# Ayrton DevOps outputs.tf

output "vpc_id" {
  value = aws_vpc.ayrton_vpc.id
}

output "subnet_id" {
  value = aws_subnet.ayrton_subnet.id
}

output "security_group_id" {
  value = aws_security_group.ayrton_sg.id
}

output "ec2_instance_public_ip" {
  value = aws_instance.ayrton_web.public_ip
}

output "alb_dns_name" {
  value = aws_lb.ayrton_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.ayrton_rds.endpoint
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.ayrton_cf.domain_name
}


output "monitoring_instance_public_ip" {
  value = aws_instance.monitoring_instance.public_ip
}

output "grafana_url" {
  value = "http://${aws_instance.monitoring_instance.public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_instance.monitoring_instance.public_ip}:9090"
}
