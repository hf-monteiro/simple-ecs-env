//****START SERVICE01 BUCKET****
resource "aws_s3_bucket" "Example-service01-bucket" {
  bucket = "Example-bucket01"
}

resource "aws_s3_bucket_acl" "Example-service01-bucket-acl" {
  bucket = aws_s3_bucket.Example-service01-bucket.id
  acl    = "private"
}

//****END SERVICE01 BUCKET
//****START  SERVICE02 BUCKET****
resource "aws_s3_bucket" "Example-service02-bucket" {
    bucket = "Example-bucket02"
}

resource "aws_s3_bucket_acl" "Example-service02-bucket-acl" {
    bucket = aws_s3_bucket.Example-service02-bucket.id
    acl = "private"
}
//****END SERVICE02 BUCKET
//****START SERVICE03 BUCKET****
resource "aws_s3_bucket" "Example-service03-bucket" {
  bucket = "Example-bucket03"
}

resource "aws_s3_bucket_acl" "Example-service03-bucket-acl" {
  bucket = aws_s3_bucket.Example-service03-bucket.id
  acl    = "private"
}
//****END SERVICE03 BUCKET

