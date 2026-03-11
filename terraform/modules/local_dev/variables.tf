variable "name_prefix" {
  description = "Environment-scoped resource name prefix."
  type        = string
}

variable "labels" {
  description = "Standard metadata labels."
  type        = map(string)
}
