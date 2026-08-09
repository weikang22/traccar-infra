output "volume_id" {
  description = "ID of the Traccar persistent EBS volume"
  value       = aws_ebs_volume.traccar_data.id
}

output "database_secret_arn" {
  description = "arn of traccar secret in secrets manager"
  value       = aws_secretsmanager_secret.traccar_database.arn
}