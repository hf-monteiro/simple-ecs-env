//Create a subnet group that can be shared amongst all private database instances
resource "aws_db_subnet_group" "private-db-subnets" {
  name       = "private-db-subnets"
  subnet_ids = [aws_subnet.private-subnets["private-1a"].id, aws_subnet.private-subnets["private-1b"].id, aws_subnet.private-subnets["private-1c"].id]
}
//****RDS CLUSTER AND INSTANCE CONFIG****
//All RDS clusters and instances should be created below. They should be grouped by the service
//and/or application that will use them.
//****START SHIPPING SERVICE RDS CONFIG****
resource "aws_rds_cluster" "Example-ship-dev" {
  cluster_identifier           = "Example-ship-dev"
  db_subnet_group_name         = aws_db_subnet_group.private-db-subnets.name
  engine                       = "aurora-postgresql"
  engine_version               = "12.8"
  availability_zones           = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_name                = "shipping"
  master_username              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_username"]
  master_password              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_password"]
  backup_retention_period      = 7
  preferred_backup_window      = "00:00-03:00"
  preferred_maintenance_window = "sun:03:00-sun:04:00"
  storage_encrypted            = true
  vpc_security_group_ids       = [aws_security_group.Example-dev-postgres.id]
}

resource "aws_rds_cluster_instance" "Example-ship-dev-instance-1" {
    identifier = "Example-ship-dev-1"
    cluster_identifier = aws_rds_cluster.Example-ship-dev.id
    instance_class = "db.t4g.medium"
    engine = aws_rds_cluster.Example-ship-dev.engine
    engine_version = aws_rds_cluster.Example-ship-dev.engine_version
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name
}
//****END SHIPPING SERVICE RDS CONFIG****
//****START ECOMMERCE SERVICE RDS CONFIG****
resource "aws_rds_cluster" "Example-integrations-dev" {
    cluster_identifier = "Example-integrations-dev"
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name
    engine = "aurora-postgresql"
    engine_version = "12.8"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    database_name = "postgres"
    master_username = jsondecode(data.aws_secretsmanager_secret_version.ecom-current.secret_string)["DATABASE_USERNAME"]
    master_password = jsondecode(data.aws_secretsmanager_secret_version.ecom-current.secret_string)["DATABASE_PASSWORD"]
    backup_retention_period = 7
    preferred_backup_window = "00:00-03:00"
    preferred_maintenance_window = "sun:03:00-sun:04:00"
    storage_encrypted = true
    vpc_security_group_ids = [aws_security_group.Example-dev-postgres.id]
}
resource "aws_rds_cluster_instance" "Example-integrations-dev-instance-1" {
    identifier = "Example-integrations-dev-1"
    cluster_identifier = aws_rds_cluster.Example-integrations-dev.id
    instance_class = "db.t4g.medium"
    engine = aws_rds_cluster.Example-integrations-dev.engine
    engine_version = aws_rds_cluster.Example-integrations-dev.engine_version
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name
}
//****END ECOMMERCE SERVICE RDS CONFIG****
//****START REPORTING SERVICE RDS CONFIG****
resource "aws_rds_cluster" "Example-report-dev" {
  cluster_identifier           = "Example-report-dev"
  db_subnet_group_name         = aws_db_subnet_group.private-db-subnets.name
  engine                       = "aurora-postgresql"
  engine_version               = "12.8"
  availability_zones           = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_name                = "reporting"
  master_username              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_username"]
  master_password              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_password"]
  backup_retention_period      = 7
  preferred_backup_window      = "00:00-03:00"
  preferred_maintenance_window = "sun:03:00-sun:04:00"
  storage_encrypted            = true
  vpc_security_group_ids       = [aws_security_group.Example-dev-postgres.id]
}

resource "aws_rds_cluster_instance" "Example-report-dev-instance-1" {
  identifier           = "Example-report-dev-1"
  cluster_identifier   = aws_rds_cluster.Example-report-dev.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.Example-report-dev.engine
  engine_version       = aws_rds_cluster.Example-report-dev.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name

}
//****END SHIPPING SERVICE RDS CONFIG****
//****START ONLINE-SERVER SERVICE RDS CONFIG****
resource "aws_rds_cluster" "Example-online-server-dev" {
    cluster_identifier = "Example-online-server-dev"
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name
    engine = "aurora-postgresql"
    engine_version = "12.8"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    database_name = "onlineserver"
    master_username = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_username"]
    master_password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_password"]
    backup_retention_period = 7
    preferred_backup_window = "00:00-03:00"
    preferred_maintenance_window = "sun:03:00-sun:04:00"
    storage_encrypted = true
    vpc_security_group_ids = [aws_security_group.Example-dev-postgres.id]
}

resource "aws_rds_cluster_instance" "Example-online-server-dev-instance-1" {
    identifier = "Example-online-server-dev-1"
    cluster_identifier = aws_rds_cluster.Example-online-server-dev.id
    instance_class = "db.t4g.medium"
    engine = aws_rds_cluster.Example-online-server-dev.engine
    engine_version = aws_rds_cluster.Example-online-server-dev.engine_version
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name

}
//****END ONLINE-SERVER SERVICE RDS CONFIG****
//****START PAYMENTSERVICE RDS CONFIG****
resource "aws_rds_cluster" "Example-paymentservice-dev" {
    cluster_identifier = "Example-paymentservice-dev"
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name
    engine = "aurora-postgresql"
    engine_version = "12.8"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    database_name = "onlineserver"
    master_username = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_username"]
    master_password = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_password"]
    backup_retention_period = 7
    preferred_backup_window = "00:00-03:00"
    preferred_maintenance_window = "sun:03:00-sun:04:00"
    storage_encrypted = true
    vpc_security_group_ids = [aws_security_group.Example-dev-postgres.id]
}

resource "aws_rds_cluster_instance" "Example-paymentservice-dev-instance-1" {
    identifier = "Example-paymentservice-dev-1"
    cluster_identifier = aws_rds_cluster.Example-paymentservice-dev.id
    instance_class = "db.t4g.medium"
    engine = aws_rds_cluster.Example-paymentservice-dev.engine
    engine_version = aws_rds_cluster.Example-paymentservice-dev.engine_version
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name

}
//****END PAYMENTSERVICE RDS CONFIG****
//****START ECOMMERCE RDS CONFIG****
resource "aws_rds_cluster" "Example-ecommerce-dev" {
  cluster_identifier           = "Example-ecommerce-dev"
  db_subnet_group_name         = aws_db_subnet_group.private-db-subnets.name
  engine                       = "aurora-postgresql"
  engine_version               = "12.8"
  availability_zones           = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_name                = "ecommerce"
  master_username              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_username"]
  master_password              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_password"]
  backup_retention_period      = 7
  preferred_backup_window      = "00:00-03:00"
  preferred_maintenance_window = "sun:03:00-sun:04:00"
  storage_encrypted            = true
  vpc_security_group_ids       = [aws_security_group.Example-dev-postgres.id]
}

resource "aws_rds_cluster_instance" "Example-ecommerce-dev-instance-1" {
  identifier           = "Example-ecommerce-dev-1"
  cluster_identifier   = aws_rds_cluster.Example-ecommerce-dev.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.Example-ecommerce-dev.engine
  engine_version       = aws_rds_cluster.Example-ecommerce-dev.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name

}
//****END ECOMMERCE RDS CONFIG****
