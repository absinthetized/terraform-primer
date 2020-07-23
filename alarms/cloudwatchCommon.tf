# this files cotains a number of cloudwatch alarms that can be parametrized and reused
# across different modules

variable "prjTag" {
    type = map(any)
}

variable "alarmNamespace" {
    type = string
}

variable "alarmPrefix" {
    type = string
}

variable "alarmTarget" {
    type = string
    description = "the dimension of the alarm, aka the instance Id to be monitored"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm" {
  alarm_name                = "${var.alarmPrefix}-high-CPU"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5" #number of contiguous periods. I find this useful: setting period to 60 secs this defines the minutes
  metric_name               = "CPUUtilization"
  namespace                 = var.alarmNamespace
  period                    = "60" #in seconds
  statistic                 = "Average"
  threshold                 = "75"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  #this limits the monitoring to our instance
  dimensions = {
    InstanceId = var.alarmTarget
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