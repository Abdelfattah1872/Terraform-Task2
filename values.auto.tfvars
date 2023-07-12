aws-region = "us-east-1"
env = "bastion"
cidrs = {
  vpc = "10.0.0.0/16",
  route-table = "0.0.0.0/0"
}
subnet_cidrs = {
  public  = "10.0.0.0/24"
  private = "10.0.1.0/24"
}