//SQS resource creation
resource "aws_sqs_queue" "service01-dev" {
    name = "Example-service01-dev.fifo"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 345600
    receive_wait_time_seconds = 0
    fifo_queue = true
}

resource "aws_sqs_queue" "service02-dev" {
    name = "Example-service02-dev.fifo"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 345600
    receive_wait_time_seconds = 0
    fifo_queue = true
}

resource "aws_sqs_queue" "service03-dev" {
    name = "Example-service03-dev.fifo"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 345600
    receive_wait_time_seconds = 0
    fifo_queue = true
}
