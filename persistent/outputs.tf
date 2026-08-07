output "volume_id" {
  description = "ID of the Traccar persistent EBS volume"
  value       = aws_ebs_volume.traccar_data.id
}