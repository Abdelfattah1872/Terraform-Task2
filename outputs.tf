output "public_instance_ips" {
  value = aws_instance.pub-instance.public_ip
}

output "private_instance_ips" {
  value = aws_instance.pvt-instance.private_ip
}