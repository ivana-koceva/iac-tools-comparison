variable "postgres_db" {
  description = "DB for Blog App"
  type        = string
  default     = "blogs"
}

variable "postgres_user" {
  description = "DB User for Blog App"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "DB Password for Blog App"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "postgres_port" {
  description = "DB Port"
  type        = number
  default     = 5432
}

variable "app_port" {
  description = "Blog App Port"
  type        = number
  default     = 8080
}