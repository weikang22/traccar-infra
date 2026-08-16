# Traccar AWS Infrastructure

Terraform-based AWS infrastructure for deploying a self-hosted [Traccar](https://www.traccar.org/) GPS tracking server.

The project started as a simple EC2 deployment and has been progressively developed into a more production-oriented architecture, incorporating Infrastructure as Code, remote Terraform state, persistent storage, secrets management, IAM, Docker Compose and plans for CI/CD and observability.

## Project Goals

The main objectives of this project are to:

* Provision AWS infrastructure using Terraform
* Deploy Traccar onto an Ubuntu EC2 instance
* Run Traccar and MariaDB using Docker Compose
* Keep application data persistent independently of the EC2 instance
* Store database credentials securely using AWS Secrets Manager
* Use IAM roles instead of static AWS credentials on the server
* Store Terraform state remotely in Amazon S3
* Separate persistent infrastructure from disposable application infrastructure
* Introduce CI/CD using GitHub Actions
* Monitor the infrastructure using Prometheus and Grafana

The project is also intended as a practical demonstration of AWS, Terraform, Linux, Docker, IAM and DevOps practices.

---

# Architecture

The current architecture consists of:

![Infrastructure Architecture](https://github.com/weikang22/traccar-infra/blob/ac3daf7f6bb4233276eb9bdae5503e7595b16679/Infrastructure%20Diagram.png "Infrastructure Architecture")

The important design principle is that the **EC2 instance is disposable while the database data and credentials are persistent**.

---

# Project Development

The infrastructure was developed incrementally rather than attempting to build the entire environment at once.

## 1. Terraform Bootstrap

The first step was establishing Terraform itself and preparing AWS access.

An AWS Terraform user was created with permissions required to provision the infrastructure.

The project was initially developed locally using Terraform commands such as:

```bash
terraform init
terraform plan
terraform apply
```

Terraform variables were introduced for values that should not be hardcoded, such as:

* AWS region
* Availability Zone
* VPC CIDR
* Subnet CIDR
* EC2 instance type
* Project/environment names

This keeps infrastructure configuration reusable between environments.

---

## 2. Remote Terraform Backend

Before continuing with the infrastructure, Terraform state was moved to a remote backend.

Amazon S3 is used to store the Terraform state:

```text
Terraform
    │
    ▼
Amazon S3
    │
    └── Terraform state
```

The backend provides persistent and centralised state rather than relying on a local `terraform.tfstate` file.

The backend itself is bootstrapped separately from the infrastructure it manages so that the state storage exists before the main Terraform configurations depend on it.

The backend configuration uses:

* S3
* Server-side encryption
* S3 versioning
* State locking using the S3 backend lockfile mechanism

Remote state provides a foundation for safely managing the infrastructure and allows multiple Terraform configurations to reference outputs from other configurations.

---

# 3. AWS Networking

The initial AWS network was deliberately kept simple.

Terraform provisions:

* VPC
* Public subnet
* Internet Gateway
* Public route table
* Route table association

The VPC and subnet CIDR ranges are configurable through Terraform variables.

The EC2 instance is deployed into the public subnet so that the initial deployment can be accessed directly.

The networking configuration can later be extended with private subnets, NAT gateways and additional security boundaries if required.

---

# 4. EC2 Instance

An Ubuntu 24.04 EC2 instance is used to host Traccar.

Terraform provisions the instance using an Ubuntu AMI and configures:

* EC2 instance
* Instance type
* Subnet
* Security group
* SSH key pair
* Public IP
* IAM instance profile
* Bootstrap/user-data script

The Ubuntu AMI is discovered through an AWS data source rather than hardcoding an AMI ID.

This allows the deployment to locate the appropriate Ubuntu image automatically.

---

# 5. Security Group

A dedicated security group controls network access to the Traccar server.

Only the required application and administration ports are exposed.

The security group is managed through Terraform so that network access is reproducible and version controlled.

The security model can be tightened further in future iterations by removing direct SSH access and using AWS Systems Manager Session Manager.

---

# 6. EC2 Bootstrap

The EC2 instance uses a bootstrap script to configure the operating system automatically.

The script is responsible for preparing the server and deploying the application.

The bootstrap process includes tasks such as:

```text
EC2 launch
    │
    ├── Update packages
    ├── Install required packages
    ├── Install Docker
    ├── Install Docker Compose
    ├── Install AWS CLI / supporting tools
    ├── Prepare application directories
    ├── Retrieve secrets
    ├── Retrieve application configuration
    └── Start Docker Compose
```

This means the EC2 instance does not require manual application installation after Terraform creates it.

---

# 7. Docker Compose

Traccar and MariaDB are deployed using Docker Compose.

The application stack consists of:

```text
Docker Compose
│
├── Traccar
│
└── MariaDB
```

Docker provides a consistent runtime environment while Compose defines how the containers interact.

The Compose configuration is stored in Git and pulled onto the EC2 instance during bootstrap.

This keeps the application deployment separate from the AWS infrastructure definition.

---

# 8. Traccar and MariaDB

Traccar is configured to use MariaDB as its database backend.

The initial deployment was verified by checking the Traccar container logs and MariaDB schema.

Successful Liquibase output confirmed that Traccar was able to connect to MariaDB:

```text
Liquibase: Update has been successful.
Database is up to date, no changesets to execute
```

The MariaDB database was also checked directly to confirm that the expected Traccar tables had been created.

Examples include:

```text
tc_devices
tc_positions
tc_users
tc_events
tc_groups
tc_geofences
```

This confirmed that the application was not simply running successfully at the web interface level, but was also communicating correctly with its database.

---

# 9. Persistent EBS Storage

The database storage was separated from the EC2 instance by using an EBS volume.

The architecture is:

```text
EC2
 │
 │ attached at runtime
 ▼
EBS Volume
 │
 └── MariaDB data
```

The EBS volume is intended to survive replacement of the EC2 instance.

This creates an important separation between:

### Disposable infrastructure

* EC2 instance
* Docker containers
* Application runtime

### Persistent infrastructure

* MariaDB data
* EBS volume
* Database credentials

The EBS volume is attached to the EC2 instance through Terraform.

Because EBS volumes are tied to an Availability Zone, the EC2 instance and EBS volume are deployed into the same Availability Zone.

The bootstrap script also checks the attached device before mounting it and avoids formatting an existing filesystem. This prevents a replacement EC2 instance from accidentally destroying the existing database.

---

# 10. Terraform Root Separation

As the infrastructure became more sophisticated, the Terraform configuration was separated according to resource lifecycle rather than simply by AWS service.

The intended structure is:

```text
traccar-infra/
│
├── bootstrap/
│
├── persistent/
│
└── application/
    |
    └── scripts/
```

### Bootstrap

Responsible for infrastructure required to initialise Terraform itself.

```text
S3 Bucket for Terraform backend
```

### Persistent

Responsible for resources that should survive application replacement:

```text
EBS database volume
Secrets Manager secret
```

### Application

Responsible for the disposable application layer:

```text
VPC
Subnet
Internet Gateway
Route tables
EC2
IAM role
Instance profile
Security group
EBS volume attachment
Application deployment
```

This separation means the application layer can be destroyed and recreated without destroying persistent database data.

For example:

```bash
cd application
terraform destroy
```

can remove the EC2 instance while leaving the database volume and credentials managed by the persistent root.

The application can then be recreated with:

```bash
terraform apply
```

and reconnect to the existing database.

---

# 11. AWS Secrets Manager

Database credentials were removed from the Terraform configuration and Docker Compose configuration.

AWS Secrets Manager is used to store the database credentials.

The architecture is:

```text
AWS Secrets Manager
        │
        │ GetSecretValue
        ▼
EC2 IAM Role
        │
        ▼
Bootstrap Script
        │
        ├── Docker Compose
        │
        └── Traccar configuration
```

The secret contains the database configuration required by MariaDB and Traccar.

Instead, the EC2 instance receives an IAM role allowing it to retrieve only the required secret.

The IAM permission is scoped to:

```text
secretsmanager:GetSecretValue
```

for the specific Traccar database secret.

This follows the principle of least privilege.

The secret value itself is deliberately not managed by Terraform. Terraform manages the Secrets Manager container, while the sensitive value is manually entered and managed separately.

---

# 12. Current Infrastructure

The project currently provides:

* Terraform-managed AWS infrastructure
* Remote Terraform state in S3
* AWS VPC and networking
* Ubuntu EC2
* Security group
* IAM instance role
* Docker and Docker Compose
* Traccar
* MariaDB
* Persistent EBS database storage
* AWS Secrets Manager
* Automated EC2 bootstrap
* Persistent/disposable infrastructure separation

---

# 13. Planned: GitHub Actions

The next phase is to introduce CI/CD using GitHub Actions.

The initial workflow will focus on Terraform validation rather than automatically modifying AWS infrastructure.

The planned pipeline is:

```text
Git push / Pull Request
        │
        ▼
GitHub Actions
        │
        ├── terraform fmt -check
        ├── terraform init
        ├── terraform validate
        └── terraform plan
```

AWS authentication will use GitHub Actions OIDC rather than long-lived AWS access keys.

Automatic `terraform apply` can be introduced later with appropriate approval and environment controls.

---

# 14. Planned: Prometheus

Prometheus will be added to provide infrastructure and container metrics.

The monitoring architecture will be:

```text
EC2
│
├── Node Exporter
│       │
│       └── Host metrics
│
├── cAdvisor
│       │
│       └── Container metrics
│
└── Prometheus
        │
        ▼
      Grafana
```

Node Exporter will provide Linux host metrics including:

* CPU
* Memory
* Disk usage
* Filesystem usage
* Network statistics

cAdvisor will provide container-level metrics for:

* Traccar
* MariaDB
* Prometheus
* Grafana

Prometheus will collect and store these metrics.

---

# 15. Planned: Grafana

Grafana will provide dashboards using Prometheus as its data source.

The intended dashboards will cover:

### Infrastructure

* CPU usage
* Memory usage
* Disk usage
* EBS utilisation
* Network traffic
* System uptime

### Containers

* Traccar CPU usage
* Traccar memory usage
* MariaDB CPU usage
* MariaDB memory usage
* Container network traffic
* Container availability

Grafana configuration will eventually be provisioned from files so that dashboards and data sources can be version controlled rather than configured manually.

---

# Deployment

## Prerequisites

The following are required:

* AWS account
* AWS CLI
* Terraform
* Git
* Docker
* SSH key pair
* Appropriate AWS permissions

---

## Configure Terraform

Clone the repository:

```bash
git clone https://github.com/weikang22/traccar-infra.git

cd traccar-infra
```

Configure the required Terraform variables using the provided example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update the values for your environment.

Do not commit sensitive values to Git.

---

# Terraform Workflow

Terraform should generally be used in the following order:

```text
1. Bootstrap
      ↓
2. Foundation
      ↓
3. Persistent
      ↓
4. Application
```

Initialise each Terraform root:

```bash
terraform init
```

Review the proposed infrastructure:

```bash
terraform plan
```

Apply the configuration:

```bash
terraform apply
```

Terraform state is stored remotely in Amazon S3.

---

# Validation

After deployment, verify the EC2 instance:

```bash
ssh ubuntu@<EC2_PUBLIC_IP>
```

Check Docker:

```bash
docker ps
```

Check the application:

```bash
docker compose ps
```

Check Traccar logs:

```bash
docker compose logs traccar
```

Check MariaDB logs:

```bash
docker compose logs database
```

The Traccar container should successfully connect to MariaDB and Liquibase should report that the database is up to date.

---

# Persistence Test

One of the key tests for this architecture is replacing the application layer without losing database data.

Destroy only the application infrastructure:

```bash
cd application

terraform destroy
```

The persistent resources should remain:

```text
EBS volume       → preserved
Database data    → preserved
Secrets Manager  → preserved
```

Recreate the application:

```bash
terraform apply
```

The new EC2 instance should:

1. Start successfully
2. Attach the existing EBS volume
3. Mount the existing filesystem
4. Retrieve the database credentials from Secrets Manager
5. Start MariaDB
6. Start Traccar
7. Connect to the existing database
8. Preserve the existing Traccar data

This demonstrates the separation between compute and persistent data.

---

# Security Considerations

The project follows several security practices:

* Database passwords are not stored in Git
* Database credentials are stored in AWS Secrets Manager
* EC2 uses an IAM role instead of static AWS credentials
* IAM permissions follow least privilege
* Terraform state is stored remotely
* EBS storage is encrypted
* Infrastructure is managed through Terraform
* Security group rules are explicitly defined
* Sensitive files are excluded using `.gitignore`

Future improvements include:

* AWS Systems Manager Session Manager instead of SSH
* Removal of unnecessary public ports
* HTTPS/TLS for Traccar
* Additional IAM hardening
* Automated security scanning
* Automated backup and recovery testing

---

# Future Improvements

Planned improvements include:

* [ ] GitHub Actions Terraform CI
* [ ] GitHub Actions OIDC authentication
* [ ] Prometheus
* [ ] Node Exporter
* [ ] cAdvisor
* [ ] Grafana
* [ ] Grafana dashboard provisioning
* [ ] Prometheus alerting
* [ ] Automated EBS snapshots
* [ ] Database backup/recovery testing
* [ ] AWS Systems Manager Session Manager
* [ ] HTTPS/TLS
* [ ] DNS configuration
* [ ] AWS monitoring and alerting
* [ ] Terraform security scanning
* [ ] Production environment separation

---

# Technologies

| Technology          | Purpose                          |
| ------------------- | -------------------------------- |
| AWS                 | Cloud infrastructure             |
| Terraform           | Infrastructure as Code           |
| Amazon S3           | Terraform remote state           |
| Amazon EC2          | Traccar compute                  |
| Amazon EBS          | Persistent database storage      |
| AWS Secrets Manager | Database credentials             |
| AWS IAM             | Authentication and authorisation |
| VPC                 | Network isolation                |
| Docker              | Application containers           |
| Docker Compose      | Container orchestration          |
| Traccar             | GPS tracking platform            |
| MariaDB             | Application database             |
| GitHub              | Source control                   |
| GitHub Actions      | CI/CD                            |
| Prometheus          | Metrics collection               |
| Grafana             | Monitoring dashboards            |

---

# Project Status

**Current stage: Core infrastructure deployed and operational.**

The Traccar server is successfully running on AWS with:

```text
Terraform
   ↓
AWS infrastructure
   ↓
EC2
   ↓
Docker Compose
   ├── Traccar
   └── MariaDB
        ↓
   Persistent EBS

EC2
   ↓
IAM Role
   ↓
Secrets Manager
   ↓
Database credentials
```

The next development stage focuses on **CI/CD and observability**, using GitHub Actions, Prometheus and Grafana.