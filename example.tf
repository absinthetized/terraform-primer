#this is a comment?!
provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

#this nis required to ssh into the machine from a remote client like putty
resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAsQtpu78GVjGAGPVCmJAJW3JtFquE8jHy3SYJLUjh/u2aAXQW/6TqYxa8DJyjt9RaJmWBAgek8vGW2F+XMcpWzRzKsH7RPHpIq8yEz7yYw2H956ZQt7H0Og3TPkirWOT3MakIKzSJgCK5GSup12SzphY7Jsrs5Csp5P053g5cwTyIXwgSrCbb5Deb5qGYXv5gFoOEqXgT9MtzXGHVOCiegeGcND044W2NZY5+22WDoaT9tpvGTxtntfIu0cNWJlIo1MEYOc0Rif1c0zPhQ8HoWqsGrjw1DunwYcaqZ8/qTJ/3wfXC9UIbQ4oXfVJ51Tx8Jv0dKfvxSeepan+4ZLVbXw== rsa-key-20200721"
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

  tags = {
    Name = "allow_ssh"
  }
}

#our VM with a given ssh key , protected by our firewall rules
resource "aws_instance" "pippo" {
  ami           = "ami-0a63f96e85105c6d3"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = aws_key_pair.ssh-key.key_name
}

#firewall rules to open postgres inbound traffic from outside
#please note: you could add as many roule as you want into a sec group. here I've created a new one just 
#for test purpouses
resource "aws_security_group" "allow_pg" {
  name        = "allow_pg"
  description = "Allow Postgres inbound traffic"

  ingress {
    description = "Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_pg"
  }
}

#add a managed postgres instance
resource "aws_db_instance" "postgres" {
  identifier             = "appdb"
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t3.micro"
  name                   = "testdb"
  username               = "testuser"
  password               = "testpassword"
  maintenance_window     = "Mon:00:00-Mon:03:00"
  publicly_accessible    = "true" #this is dangerous in prod unless you assign to a security group with specific innound IPs
  vpc_security_group_ids = [aws_security_group.allow_pg.id]

  final_snapshot_identifier = "ops"
}