output "alb_dns_name" {
  value       = aws_lb.moodle.dns_name
  description = "The domain name of the load balancer"
}


/*
output "template_vars" {
  value = {
    admin_password  = var.admin_password
    password        = var.password
    server_port     = var.server_port
    username        = var.username
    website_address = var.website_address
  }
}
*/


