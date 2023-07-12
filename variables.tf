variable "aws-region" {
  type = string
  default = ""
}

variable "cidrs" {
  type = map(string)
  default = {"":""}
}

variable "subnet_cidrs" {
  type    = map(string)
  default = {"":""}
}