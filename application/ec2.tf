data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "traccar" {
  key_name   = "traccar"
  public_key = file("~/.ssh/traccar.pub")
}

resource "aws_instance" "traccar" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.traccar.id]
  associate_public_ip_address = true
  availability_zone           = var.availability_zone
  user_data_replace_on_change = true

  key_name = aws_key_pair.traccar.key_name

  iam_instance_profile = aws_iam_instance_profile.traccar.name

  user_data = file("scripts/bootstrap.sh")

  tags = {
    Name = "traccar-server"
  }
}

resource "aws_volume_attachment" "traccar_data" {
  device_name = "/dev/sdf"
  volume_id   = data.terraform_remote_state.persistent.outputs.volume_id
  instance_id = aws_instance.traccar.id

  force_detach = false

  depends_on = [aws_instance.traccar] # Ensure the EC2 instance is created before attaching the volume. Not entirely necessary as the instance ID variable is referenced, therefore, terraform understands to wait for the instance to be provisioned.
}