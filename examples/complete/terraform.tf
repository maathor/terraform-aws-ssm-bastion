terraform{
  backend "local" {
    path = "local_tfstate/demo.tfstate"
  }
}

provider "aws" {
  region  = local.region
}