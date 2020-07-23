variable "prjTag" {
    type = map(any)
}

#this is required to ssh into the machine from a remote client like putty
resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAsQtpu78GVjGAGPVCmJAJW3JtFquE8jHy3SYJLUjh/u2aAXQW/6TqYxa8DJyjt9RaJmWBAgek8vGW2F+XMcpWzRzKsH7RPHpIq8yEz7yYw2H956ZQt7H0Og3TPkirWOT3MakIKzSJgCK5GSup12SzphY7Jsrs5Csp5P053g5cwTyIXwgSrCbb5Deb5qGYXv5gFoOEqXgT9MtzXGHVOCiegeGcND044W2NZY5+22WDoaT9tpvGTxtntfIu0cNWJlIo1MEYOc0Rif1c0zPhQ8HoWqsGrjw1DunwYcaqZ8/qTJ/3wfXC9UIbQ4oXfVJ51Tx8Jv0dKfvxSeepan+4ZLVbXw== rsa-key-20200721"

  tags = merge(var.prjTag, {})
}

#firewall rules to open only ssh inbound trafic and lock anything else
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH to VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.prjTag,
    { Name = "allow_ssh" }
  )
}

#our VM with a given ssh key , protected by our firewall rules
resource "aws_instance" "pippo" {
  monitoring    = true
  ami           = "ami-0a63f96e85105c6d3"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = aws_key_pair.ssh-key.key_name

  tags = merge(
    var.prjTag,
    { Name = "pippo" }
  )
}

##some metric alarms!
module "cloudwatchCommon" {
    source = "../alarms"

    prjTag = var.prjTag
    alarmNamespace = "AWS/EC2"
    alarmPrefix = aws_instance.pippo.tags["Name"]
    alarmTarget = aws_instance.pippo.id
}
