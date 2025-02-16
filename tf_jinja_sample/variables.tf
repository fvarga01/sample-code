
variable "region" {
  description = "The AWS region"
  type        = string
  
  default     = "us-west-2"
  
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  
  default     = 3
  
}

variable "instance_type" {
  description = "Type of instance"
  type        = string
  
  default     = "t2.micro"
  
}
