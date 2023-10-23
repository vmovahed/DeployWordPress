locals {
       region = "us-east-1"
       vpc = "vpc-0a28a064bc6db2258"
       ssh_user = "ubuntu"
       ami = "ami-08c40ec9ead489470"
       itype = "t2.micro"
       subnet = "subnet-01c0f9f4c71cd82e8"
       publicip = true
       keyname = "wordpress-server-key-pair"
       public_key_path = "/home/vmadmin/DeployWordPress/myseckey.pub"
       private_key_path = "/home/vmadmin/DeployWordPress/myseckey"
       secgroupname = "Deploy-Sec-Group"
}


resource "aws_key_pair" "myec2keypair" {
  key_name   = local.keyname
  public_key = file(local.public_key_path)

}

resource "aws_security_group" "myproject-sg" {
     name = local.secgroupname
     description = local.secgroupname
     vpc_id = local.vpc

  // To Allow SSH Transport
  ingress {
       from_port = 22
       protocol = "tcp"
       to_port = 22
       cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
       from_port = 80
       protocol = "tcp"
       to_port = 80
       cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 443 Transport
  ingress {
       from_port = 443
       protocol = "tcp"
       to_port = 443
       cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
       from_port       = 0
       to_port         = 0
       protocol        = "-1"
       cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
        create_before_destroy = true
  }
}

resource "aws_instance" "ec2-deploy" {
      ami = local.ami
      instance_type = local.itype
      subnet_id = local.subnet
      associate_public_ip_address = local.publicip
      key_name = local.keyname

      vpc_security_group_ids = [
        aws_security_group.myproject-sg.id
  ]
     root_block_device {
          delete_on_termination = true
          volume_size = 50
          volume_type = "gp2"
      }
     tags = {
         Name ="WP-Server01"
         Environment = "PROD"
         OS = "UBUNTU"
         Managed = "INFRA"
      }

      depends_on = [ aws_security_group.myproject-sg ]
  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Wait for SSH connection to be ready...'"
    ]
  }

  provisioner "local-exec" {
    #To populate the Ansible inventory file
    command = "echo ${self.public_ip} > myhosts"
  }

provisioner "local-exec" {
 #To execute the ansible playbook
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} wordpress-deploy.yml"
  }

}
output "ec2instance" {
  value = aws_instance.ec2-deploy.public_ip
}

