#Ec2 creation
resource "aws_instance" "myec2" {
    ami = var.ami_id
    instance_type = var.instance_type
    key_name=aws_key_pair.keypair.key_name
    vpc_security_group_ids=[aws_security_group.allow_ports.id]
    user_data=<<-EOF
                 #!/bin/bash
                sudo yum install docker -y 
                sudo systemctl start docker
                sudo groupadd docker
                sudo usermod -aG docker $USER
                chmod 777 /var/run/docker.sock
                newgrp docker
                docker run -d --rm --name jenkins     -p 8080:8080 -p 50000:50000     lforlinux/jenkinspipeline:version1
                sudo yum install java-1.8.0-openjdk -y 
                sudo yum install python3
                EOF

    tags = {
        Name="Terraform Created Instance"
    }
}

#creating key pair
resource "aws_key_pair" "keypair" {
    key_name="terraformkeypair"
    public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDowU4l0FXxQkcC+8OiYUNyldCBVv9LuROvh0EAT66z48lhZdJamwHg+v3GsUxD66ZiPtNe28YWifc1D29O4UALJnvWRB+1SSIOWQoQZTisXQKeYDtNsr7Wi/tXFBbtW10ftj75G6Ax4QY6bRKu3bJn9dO7YYK+DXyuw68rq0tNCasFMNE4LWXPErJYZ0iY24DTsTpXJ7iSbp3/zseJbZKq5/+6NQ4ilV9p9j4zxMsMnSTVUeMSuuQJPhASS/dKKd/5zTT2kfDRPdfW1wltZsKbW+Pu7MaTV/fJAjYMM0C02vgufzFSzn8L0BOZN8tHgFGJcs5pyhuYutfVAoGrYjdF root@ip-172-31-94-27.ec2.internal"
}

#creating elastic IP
resource "aws_eip" "myeip"{
    vpc="true"
    instance=aws_instance.myec2.id
}

#get default vpc
resource "aws_default_vpc" "default" {
    tags={
        Name="Default vpc"
    }
}

resource "aws_security_group" "allow_ports"{
    name="allow_ports"
    description="Allow inbound traffic"
    vpc_id=aws_default_vpc.default.id
    ingress{
        description="http from vpc"
        from_port=80
        to_port=80
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
    }
    ingress{
        description="ssh from vpc"
        from_port=22
        to_port=22
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
    }
    ingress{
        description="tomcat port from vpc"
        from_port=8080
        to_port=8080
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
    }
    ingress{
        description="TLS from vpc"
        from_port=443
        to_port=443
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
    }
    egress{
        description="outbound from vpc"
        from_port=0
        to_port=0
        protocol="-1"
        cidr_blocks=["0.0.0.0/0"]
    }

    tags ={
        Name="myterraformSG"
    }

}
