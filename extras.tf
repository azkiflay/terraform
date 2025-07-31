resource "aws_security_group" "moodle_sg" { 
    name = "allow_tcp_8080"
    description = "Allow TCP traffic on port 8080"
    ingress { 
        from_port = var.server_port # 8080
        protocol = "tcp"
        to_port = var.server_port # 8080
        cidr_blocks = ["0.0.0.0/0"] # Allow traffic from all possible IP addresses
        }
}