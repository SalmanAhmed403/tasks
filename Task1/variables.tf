variable "aws_region" {
  description = "region for resources"
  type        = string
  default     = "ap-southeast-1" //pls add your own zone/region, for this task I had used SINGAPORE
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "project_tags" {
  description = "Tags for the project"
  type        = map(string)
  default = {
    Project     = "Task1"   //You can rename it what ever you like
    Environment = "Dev"    //its upto u which enviorment u are defining for tracking 
  }
}