# Quick Setup - GraTech CometX Azure

# Default setup (creates new resources)
.\setup-azure.ps1

# With custom subscription
.\setup-azure.ps1 -SubscriptionId "your-subscription-id"

# Delete existing resources first, then recreate
.\setup-azure.ps1 -DeleteExisting

# Custom resource group and location
.\setup-azure.ps1 -ResourceGroupName "my-rg" -Location "eastus"

# For different GitHub org/repo
.\setup-azure.ps1 -GitHubOrg "myorg" -GitHubRepo "myrepo"
