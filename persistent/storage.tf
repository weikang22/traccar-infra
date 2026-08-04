resource "aws_ebs_volume" "traccar_data" {
  availability_zone = var.availability_zone # must be in the same AZ as the EC2 instance
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  encrypted         = true


  tags = {
    Name = "traccar-data"
  }
}