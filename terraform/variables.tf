variable "db_name" {
  type    = string
  default = "stock_multi_depot"
}

variable "db_user" {
  type    = string
  default = "stock_user"
}

variable "db_password" {
  type      = string
  default   = "stock_pass"
  sensitive = true
}

variable "db_root_password" {
  type      = string
  default   = "root_pass"
  sensitive = true
}

variable "app_port" {
  description = "Host port for the frontend (nginx) container."
  type        = number
  default     = 9091 # different from docker-compose's 9090 so both can coexist
}
