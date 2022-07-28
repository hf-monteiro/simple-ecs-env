resource "aws_sqs_queue" "ecommerce-dev" {
    name = "ecommerce-dev.fifo"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 345600
    receive_wait_time_seconds = 0
    fifo_queue = true
}

resource "aws_sqs_queue" "csv-service-dev" {
    name = "Example-csv-service-dev.fifo"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 345600
    receive_wait_time_seconds = 0
    fifo_queue = true
}

resource "aws_sqs_queue" "online-server-dev" {
    name = "Example-dev.fifo"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 345600
    receive_wait_time_seconds = 0
    fifo_queue = true
}
