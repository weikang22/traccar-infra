resource "aws_secretsmanager_secret" "traccar_database" {
  name        = "${var.project_name}/${var.environment}/database"
  description = "Database credentials for ${var.project_name} in ${var.environment} environment for mariadb"

  recovery_window_in_days = 0 # no recovery window - deletes immediately. in production, add a recovery window of 7 days or more to prevent accidental deletion

  tags = {
    Name        = "${var.project_name}-${var.environment}-database"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = false
  }
}