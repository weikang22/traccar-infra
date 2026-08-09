data "terraform_remote_state" "persistent" {
  backend = "s3"

  config = {
    bucket = "weikang-traccar-terraform-state"
    key    = "traccar/dev/persistent/terraform.tfstate"
    region = "eu-west-2"
  }

}