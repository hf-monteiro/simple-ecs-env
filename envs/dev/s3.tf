//****START example SERVICE BUCKET****
resource "aws_s3_bucket" "Example-example-bucket" {
  bucket = "Example-example-labels-07-26-2022"
}

resource "aws_s3_bucket_acl" "Example-example-bucket-acl" {
  bucket = aws_s3_bucket.Example-example-bucket.id
  acl    = "private"
}

//****END example SERVICE BUCKET

//****START ONLINE SERVICE BUCKET****
resource "aws_s3_bucket" "Example-online-server-bucket" {
    bucket = "Example-online-server-dev-07-26-2022"
}

resource "aws_s3_bucket_acl" "Example-online-server-bucket-acl" {
    bucket = aws_s3_bucket.Example-online-server-bucket.id
    acl = "private"
}
//****START REPORTING SERVICE BUCKET****
resource "aws_s3_bucket" "Example-reporting-bucket" {
  bucket = "Example-report-service-07-26-2022"
}

resource "aws_s3_bucket_acl" "Example-reporting-bucket-acl" {
  bucket = aws_s3_bucket.Example-reporting-bucket.id
  acl    = "private"
}

//****END REPORTING SERVICE BUCKET

//****START CSV SERVICE BUCKET****
resource "aws_s3_bucket" "Example-csv-service-bucket" {
    bucket = "csv-dev-service-07-26-2022"
}

resource "aws_s3_bucket_acl" "Example-csv-service-bucket-acl" {
    bucket = aws_s3_bucket.Example-csv-service-bucket.id
    acl = "private"
}
//****START IMAGE SERVICE BUCKET****
resource "aws_s3_bucket" "Example-imageservice-bucket" {
    bucket = "Example-api-dev-test-07-26-2022"
}

resource "aws_s3_bucket_acl" "Example-imageservice-bucket-acl" {
    bucket = aws_s3_bucket.Example-imageservice-bucket.id
    acl = "private"
}

//****END IMAGE SERVICE BUCKET
//****START ECOMMERCE BUCKET****
resource "aws_s3_bucket" "Example-ecommerce-bucket" {
  bucket = "Example-ecommerce-dev-07-26-2022"
}

resource "aws_s3_bucket_acl" "Example-ecommerce-acl" {
  bucket = aws_s3_bucket.Example-ecommerce-bucket.id
  acl    = "private"
}

//****END ECOMMERCE BUCKET
