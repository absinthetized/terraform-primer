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

  tags = merge(
    var.prjTag,
    { Name = "allow_pg" }
  )
}

#add a managed postgres instance
resource "aws_db_instance" "postgres" {
  identifier             = "appdb"
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t2.micro"
  name                   = "testdb"
  username               = "testuser"
  password               = "testpassword"
  maintenance_window     = "Mon:00:00-Mon:03:00"
  publicly_accessible    = "true" #this is dangerous in prod unless you assign to a security group with specific innound IPs
  vpc_security_group_ids = [aws_security_group.allow_pg.id]

  final_snapshot_identifier = "ops"

  tags = merge(var.prjTag, {})
}

##some metric alarms!

resource "aws_cloudwatch_metric_alarm" "RDS-high-CPU" {
  alarm_name                = "${aws_db_instance.postgres.identifier}-high-CPU"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5" #number of contiguous periods. I find this useful: setting period to 60 secs this defines the minutes
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "60" #in seconds
  statistic                 = "Average"
  threshold                 = "75"
  alarm_description         = "This metric monitors RDS cpu utilization"
  insufficient_data_actions = []

  #this limits the monitoring to our instance
  dimensions = {
    InstanceId = aws_db_instance.postgres.id
  }

  tags = merge(var.prjTag, {})
}

resource "aws_cloudwatch_metric_alarm" "RDS-connection-limit" {
  alarm_name                = "${aws_db_instance.postgres.identifier}-connections-limit"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5" #number of contiguous periods. I find this useful: setting period to 60 secs this defines the minutes
  metric_name               = "DatabaseConnections"
  namespace                 = "AWS/RDS"
  period                    = "60" #in seconds
  statistic                 = "Average"
  threshold                 = "5" #this depends on your instance type. maybe by using a metric query you coloud iprove this
  alarm_description         = "This metric monitors RDS connections"
  insufficient_data_actions = []

  #this limits the monitoring to our instance
  dimensions = {
    InstanceId = aws_db_instance.postgres.id
  }

  tags = merge(var.prjTag, {})
}

resource "aws_cloudwatch_metric_alarm" "RDS-storage-limit" {
  alarm_name                = "${aws_db_instance.postgres.identifier}-storage-limit"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5" #number of contiguous periods. I find this useful: setting period to 60 secs this defines the minutes
  metric_name               = "FreeStorageSpace"
  namespace                 = "AWS/RDS"
  period                    = "60" #in seconds
  statistic                 = "Average"
  threshold                 = "75"
  alarm_description         = "This metric monitors RDS connections"
  insufficient_data_actions = []

  #this limits the monitoring to our instance
  dimensions = {
    InstanceId = aws_db_instance.postgres.id
  }

  tags = merge(var.prjTag, {})
}