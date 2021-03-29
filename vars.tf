variable "prefix" {
  description = "The prefix which should be used for all resources"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
}

variable "username" {
  description = "Admin Username for the VM"
}

variable "password" {
  description = "Password for Admin User"
}

variable "number_of_vms" {
  description = "Number of virtual Machines to deploy"
}

variable "tag" {
  description = "Tag for all the resources"
}
