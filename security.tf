resource "aws_security_group" "traccar" {
  name        = "traccar-sg"
  description = "Security group for Traccar server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from home"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "Traccar UI interface"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"

    cidr_blocks = [var.ssh_cidr]
  }

  egress { # required to specifically re-create as Terrafrom removes the default allow all egress
    from_port = 0
    to_port   = 0
    protocol  = "-1" # equivalent to all ports

    cidr_blocks = ["0.0.0.0/0"]
  }
}