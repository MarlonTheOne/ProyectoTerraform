resource "aws_vpc" "VPC-CLASES" {
    cidr_block = "192.168.0.0/16"

    tags = {
      "Name" = "VPC-CLASES"
    }      
}



resource "aws_internet_gateway" "INTERNET-GW-CLASES" {
    vpc_id = aws_vpc.VPC-CLASES.id  
}



resource "aws_subnet" "SUBNET-PUBLIC" {

    vpc_id = aws_vpc.VPC-CLASES.id
    cidr_block = "192.168.0.0/24"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "SUBNET-PUBLIC"
    }  
}


resource "aws_subnet" "SUBNET-PUBLIC-B" {

    vpc_id = aws_vpc.VPC-CLASES.id
    cidr_block = "192.168.3.0/24"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "SUBNET-PUBLIC-B"
    }  
}




resource "aws_subnet" "SUBNET-PRIVATE-A" {
    vpc_id = aws_vpc.VPC-CLASES.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "SUBNET-PRIVATE"
    }
  
}

resource "aws_subnet" "SUBNET-PRIVATE-B" {
    vpc_id = aws_vpc.VPC-CLASES.id
    cidr_block = "192.168.2.0/24"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "SUBNET-PRIVATE"
    }
  
}



resource "aws_route_table" "ROUTES-PUBLIC" {
    vpc_id = aws_vpc.VPC-CLASES.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.INTERNET-GW-CLASES.id
    }

    tags = {
      "Name" = "ROUTES-PUBLIC"
    }
  
}

resource "aws_route_table_association" "ROUTES-SUBNETS-ASSOCIATION" {
    subnet_id = aws_subnet.SUBNET-PUBLIC.id
    route_table_id = aws_route_table.ROUTES-PUBLIC.id  
}



resource "aws_route_table" "ROUTES-PUBLIC-B" {
    vpc_id = aws_vpc.VPC-CLASES.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.INTERNET-GW-CLASES.id
    }

    tags = {
      "Name" = "ROUTES-PUBLIC-B"
    }  
}

resource "aws_route_table_association" "ROUTES-SUBNETS-ASSOCIATION-B" {
    subnet_id = aws_subnet.SUBNET-PUBLIC-B.id
    route_table_id = aws_route_table.ROUTES-PUBLIC-B.id  
}





resource "aws_eip" "EIP-NAT-GW" {
    vpc = true

    tags = {
        Name = "EIP-NAT-GW"
    }  
}

resource "aws_nat_gateway" "NAT-GW-CLASES" {
    allocation_id = aws_eip.EIP-NAT-GW.id
    subnet_id = aws_subnet.SUBNET-PUBLIC.id

    tags = {
      "Name" = "NAT-GW-CLASES"
    }
}



resource "aws_route_table" "ROUTES-PRIVATE-A" {
      vpc_id = aws_vpc.VPC-CLASES.id

      route {
          cidr_block = "0.0.0.0/0"
          nat_gateway_id = aws_nat_gateway.NAT-GW-CLASES.id
      }

      tags = {
        "Name" = "ROUTES-PRIVATE"
      }
}


resource "aws_route_table_association" "ROUTES-SUBNETS-PRIVATE-ASSOCIATION-A" {
    subnet_id = aws_subnet.SUBNET-PRIVATE-A.id
    route_table_id = aws_route_table.ROUTES-PRIVATE-A.id  
}

resource "aws_route_table" "ROUTES-PRIVATE-B" {
    vpc_id = aws_vpc.VPC-CLASES.id

    route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.NAT-GW-CLASES.id
    }
    
    tags = {
      "Name" = "ROUTES-PRIVATE-B"
    }  
}

resource "aws_route_table_association" "ROUTES-SUBNETS-PRIVATE-ASSOCIATION-B" {
    subnet_id = aws_subnet.SUBNET-PRIVATE-B.id
    route_table_id = aws_route_table.ROUTES-PRIVATE-B.id  
}



resource "aws_security_group" "SG-LINUX" {
    name = "Allow_Traffic"
    description = "Allow_Traffic"
    vpc_id = aws_vpc.VPC-CLASES.id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
      from_port = 8
      to_port = 0
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all ping"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "SG-LINUX"
    }
}



resource "aws_network_interface" "NIC-LINUX" {
    subnet_id = aws_subnet.SUBNET-PUBLIC.id
    private_ips = ["192.168.0.50"]
    security_groups = [aws_security_group.SG-LINUX.id]  
}


resource "aws_network_interface" "NIC-LINUX-PRIVATE-A" {
    subnet_id = aws_subnet.SUBNET-PRIVATE-A.id
    private_ips = ["192.168.1.50"]
    security_groups = [aws_security_group.SG-LINUX.id]   
}

resource "aws_network_interface" "NIC-LINUX-PRIVATE-B" {
    subnet_id = aws_subnet.SUBNET-PRIVATE-B.id
    private_ips = ["192.168.2.50"]
    security_groups = [aws_security_group.SG-LINUX.id]   
}





resource "aws_eip" "EIP-LINUX" {
    vpc = true
    network_interface = aws_network_interface.NIC-LINUX.id
    associate_with_private_ip = "192.168.0.50"
    depends_on = [
      aws_internet_gateway.INTERNET-GW-CLASES
    ]  
}




output "SERVER-PUBLIC-IP" {
    value = aws_eip.EIP-LINUX   
}


resource "aws_instance" "EC2-LINUX" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "web-demo"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LINUX.id
    }

    tags = {
      "Name" = "EC2-LINUX"
    }
     
}


resource "aws_instance" "EC2-LINUX-PRIVATE-A" {
    ami = "ami-04c30646bdedddea5"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "web-demo"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LINUX-PRIVATE-A.id
    }

     user_data = <<-EOF
            #!/bin/bash            
            sudo systemctl enable httpd
            sudo systemctl start httpd
            EOF

    tags = {
      "Name" = "EC2-LINUX-PRIVATE-A"
    }     
}

resource "aws_instance" "EC2-LINUX-PRIVATE-B" {
    ami = "ami-04c30646bdedddea5"
    instance_type = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "web-demo"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LINUX-PRIVATE-B.id
    }

    user_data = <<-EOF
            #!/bin/bash            
            sudo systemctl enable httpd
            sudo systemctl start httpd
            EOF


    tags = {
      "Name" = "EC2-LINUX-PRIVATE-B"
    }
     
}


output "MY-SERVER-PRIVATE-IP" {
    value = aws_instance.EC2-LINUX.private_ip  
}


output "server_id" {
    value = aws_instance.EC2-LINUX.id  
}







resource "aws_security_group" "SG-LOADBALANCER" {
    name = "Allow_Traffic_LB"
    description = "Allow_Traffic_LB"
    vpc_id = aws_vpc.VPC-CLASES.id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "SG-LOADBALANCER"
    }
}





resource "aws_lb" "LOADBALANCER-CLASES" {
  name = "LOADBALANCER-CLASES"
  internal = false
  ip_address_type = "ipv4"
  load_balancer_type = "application"
  subnets = [aws_subnet.SUBNET-PUBLIC.id, aws_subnet.SUBNET-PUBLIC-B.id]

  security_groups = [aws_security_group.SG-LOADBALANCER.id]

  tags = {
    "Name" = "LOADBALANCER-CLASES"
  }
  
}


resource "aws_lb_target_group" "TARGET-GROUP-LB" {
  name = "TARGET-GROUP-LB"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.VPC-CLASES.id
  
  # stickiness {
  #   type = "lb_cookie"
  # }

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 10    
  }  
}

resource "aws_lb_listener" "LISTENER-WEB-CLASES" {
  load_balancer_arn = aws_lb.LOADBALANCER-CLASES.arn
  port = "80" 
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TARGET-GROUP-LB.arn
    type = "forward"
  }  
}

resource "aws_lb_target_group" "TARGET-GROUP-CLASES" {
  name = "TARGET-GROUP-CLASES"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.VPC-CLASES.id  
}




resource "aws_lb_target_group_attachment" "ATTACH-TARGET-GROUP-A" {
  count = 2
  target_group_arn = aws_lb_target_group.TARGET-GROUP-LB.arn
  target_id = aws_instance.EC2-LINUX-PRIVATE-B.id
  # target_id = "${element(split(",", join(",", aws_instance.EC2-LINUX-PRIVATE.*.id)), count.index)}"
} 
resource "aws_lb_target_group_attachment" "ATTACH-TARGET-GROUP-B" {
  count = 2
  target_group_arn = aws_lb_target_group.TARGET-GROUP-LB.arn
  target_id = aws_instance.EC2-LINUX-PRIVATE-A.id  
}