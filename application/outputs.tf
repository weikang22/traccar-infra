output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "aws_ami" {
  value = data.aws_ami.ubuntu.id
}

output "instance_public_ip" {
  value = aws_instance.traccar.public_ip
}