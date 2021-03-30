variable "prefix" {
  description = "The prefix which should be used for all resources"
  default = "webserver"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "eastus"
}

variable "username" {
  description = "Admin Username for the VM"
  default = "root"
}

variable "password" {
  description = "Password for Admin User"
  default - "Welcome@123"
}

variable "number_of_vms" {
  description = "Number of virtual Machines to deploy"
  default = 2
}

variable "tag" {
  description = "Tag for all the resources"
  default = "1. Deploy a Web Server"
}
