terraform {
  backend "s3" {
    bucket         = "weikang-traccar-terraform-state"
    key            = "traccar/dev/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    use_lockfile   = true
  }
}