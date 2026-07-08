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

  key_name = aws_key_pair.traccar.key_name

  user_data = file("scripts/bootstrap.sh")

  tags = {
    Name = "traccar-server"
  }
}