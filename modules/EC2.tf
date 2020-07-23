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

resource "aws_cloudwatch_metric_alarm" "EC2-high-CPU" {
  alarm_name                = "${aws_instance.pippo.tags["Name"]}-high-CPU"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5" #number of contiguous periods. I find this useful: setting period to 60 secs this defines the minutes
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60" #in seconds
  statistic                 = "Average"
  threshold                 = "75"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  #this limits the monitoring to our instance
  dimensions = {
    InstanceId = aws_instance.pippo.id
  }

  tags = merge(var.prjTag, {})
}

# also set a notification policy!
#not sure about this but seems that terraform can't send mails config...
#I've found this snippet... config it as per your needs

# resource "aws_sns_topic" "alarm" {
#   name = "alarms-topic"
#   delivery_policy = <<EOF
# {
#   "http": {
#     "defaultHealthyRetryPolicy": {
#       "minDelayTarget": 20,
#       "maxDelayTarget": 20,
#       "numRetries": 3,
#       "numMaxDelayRetries": 0,
#       "numNoDelayRetries": 0,
#       "numMinDelayRetries": 0,
#       "backoffFunction": "linear"
#     },
#     "disableSubscriptionOverrides": false,
#     "defaultThrottlePolicy": {
#       "maxReceivesPerSecond": 1
#     }
#   }
# }
# EOF

#   provisioner "local-exec" {
#     command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email}"
#   }
# }