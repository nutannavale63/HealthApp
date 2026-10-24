# RDS MySQL Database for BBHealthApp
resource "aws_db_subnet_group" "bbhealthapp_db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${var.project_name}-db-subnet-group"
    }
  )
}

resource "aws_security_group" "bbhealthapp_db_sg" {
  name_prefix = "${var.project_name}-db-sg-"
  description = "Security group for RDS MySQL database"
  vpc_id      = module.vpc.vpc_id

  # Allow MySQL access from EKS nodes
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${var.project_name}-db-sg"
    }
  )
}

resource "aws_db_instance" "bbhealthapp_db" {
  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true
  db_subnet_group_name   = aws_db_subnet_group.bbhealthapp_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.bbhealthapp_db_sg.id]
  
  # Database credentials
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Backup and maintenance
  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.db_backup_window
  maintenance_window      = var.db_maintenance_window
  multi_az               = var.db_multi_az
  
  # Performance and monitoring
  performance_insights_enabled = var.db_performance_insights_enabled
  monitoring_interval          = var.db_monitoring_interval
  monitoring_role_arn         = var.db_monitoring_role_arn
  
  # Network
  publicly_accessible = false
  skip_final_snapshot = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-db-final-snapshot" : null

  # Deletion protection for production
  deletion_protection = var.environment == "prod" ? true : false

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${var.project_name}-mysql"
    }
  )

  # Ensure DB is created before EKS cluster tries to connect
  depends_on = [module.vpc]
}

# Parameter group for MySQL
resource "aws_db_parameter_group" "bbhealthapp_db_parameter_group" {
  name   = "${var.project_name}-db-parameter-group"
  family = "mysql8.0"

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${var.project_name}-db-parameter-group"
    }
  )
}
