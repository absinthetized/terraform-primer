#this is a comment?!
provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

#As the project grows up you need to group resources to have an overview of them
#let use a Resource Group
resource "aws_resourcegroups_group" "terraform-learn" {
  name = "terraform-learn"
  tags = {
    Group = "TFL" #this must be equal to the one in the query but I do not know how to interpolate a query...
  }

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": ["AWS::AllSupported"],
      "TagFilters": [{
        "Key": "Group",
        "Values": ["TFL"]
      }]
    }
    JSON
  }
}

#----------------------------------- COMPUTE -----------------------------------

module "EC2" {
  source = "./EC2"
  prjTag = aws_resourcegroups_group.terraform-learn.tags
}

#----------------------------------- MANAGED DB -----------------------------------

module "RDS" {
  source = "./RDS"
  prjTag = aws_resourcegroups_group.terraform-learn.tags
}
