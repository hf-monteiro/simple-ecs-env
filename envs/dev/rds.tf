//Create a subnet group to share with all the resources
resource "aws_db_subnet_group" "private-db-subnets" {
  name       = "private-db-subnets"
  subnet_ids = [aws_subnet.private-subnets["private-1a"].id, aws_subnet.private-subnets["private-1b"].id, aws_subnet.private-subnets["private-1c"].id]
}
//****RDS CLUSTER AND INSTANCE CONFIG****
//All RDS clusters and instances should be created below. They should be grouped by the service
//****START example SERVICE01 RDS CONFIG****
resource "aws_rds_cluster" "Example-service01-dev" {
  cluster_identifier           = "Example-service01-dev"
  db_subnet_group_name         = aws_db_subnet_group.private-db-subnets.name
  engine                       = "aurora-postgresql"
  engine_version               = "12.8"
  availability_zones           = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_name                = "service01"
  master_username              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_username"]
  master_password              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_password"]
  backup_retention_period      = 7
  preferred_backup_window      = "00:00-03:00"
  preferred_maintenance_window = "sun:03:00-sun:04:00"
  storage_encrypted            = true
  vpc_security_group_ids       = [aws_security_group.Example-dev-postgres.id]
}

resource "aws_rds_cluster_instance" "Example-service01-dev-instance-1" {
    identifier = "Example-service01-dev-1"
    cluster_identifier = aws_rds_cluster.Example-service01-dev.id
    instance_class = "db.t4g.medium"
    engine = aws_rds_cluster.Example-service01-dev.engine
    engine_version = aws_rds_cluster.Example-service01-dev.engine_version
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name
}
//****END example SERVICE01 RDS CONFIG****
//****START example SERVICE02 RDS CONFIG****
resource "aws_rds_cluster" "Example-service02-dev" {
    cluster_identifier = "Example-service02-dev"
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
resource "aws_rds_cluster_instance" "Example-service02-dev-instance-1" {
    identifier = "Example-service02-dev-1"
    cluster_identifier = aws_rds_cluster.Example-service02-dev.id
    instance_class = "db.t4g.medium"
    engine = aws_rds_cluster.Example-service02-dev.engine
    engine_version = aws_rds_cluster.Example-service02-dev.engine_version
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name
}
//****END example SERVICE02 RDS CONFIG****
//****START example SERVICE03 RDS CONFIG****
resource "aws_rds_cluster" "Example-service03-dev" {
  cluster_identifier           = "Example-service03-dev"
  db_subnet_group_name         = aws_db_subnet_group.private-db-subnets.name
  engine                       = "aurora-postgresql"
  engine_version               = "12.8"
  availability_zones           = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_name                = "service03"
  master_username              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_username"]
  master_password              = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["database_password"]
  backup_retention_period      = 7
  preferred_backup_window      = "00:00-03:00"
  preferred_maintenance_window = "sun:03:00-sun:04:00"
  storage_encrypted            = true
  vpc_security_group_ids       = [aws_security_group.Example-dev-postgres.id]
}

resource "aws_rds_cluster_instance" "Example-service03-dev-instance-1" {
  identifier           = "Example-service03-dev-1"
  cluster_identifier   = aws_rds_cluster.Example-service03-dev.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.Example-service03-dev.engine
  engine_version       = aws_rds_cluster.Example-service03-dev.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.private-db-subnets.name

}
//****END example SERVICE03 RDS CONFIG****