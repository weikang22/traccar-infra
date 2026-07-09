resource "aws_ebs_volume" "traccar_data" {
  availability_zone = aws_instance.traccar.availability_zone # must be in the same AZ as the EC2 instance
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  encrypted         = true


  tags = {
    Name = "traccar-data"
  }
}

resource "aws_volume_attachment" "traccar_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.traccar_data.id
  instance_id = aws_instance.traccar.id

  force_detach = false

  depends_on = [aws_instance.traccar] # Ensure the EC2 instance is created before attaching the volume. Not entirely necessary as the instance ID variable is referenced, therefore, terraform understands to wait for the instance to be provisioned.
}