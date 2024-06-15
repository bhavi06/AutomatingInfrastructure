variable "region"{
    type = string
    default = "us-east-1"
}


variable "ec2name" {
    type = string
    default = "devserver"
}

variable "ami" {
    type = string
    default = "ami-0069eac59d05ae12b"
}

variable "instance_type" {
    type = string
default = "t2.micro"
}


