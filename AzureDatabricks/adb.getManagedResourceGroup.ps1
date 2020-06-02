<#
Get the Managed Resource Group for each Azure Databricks Workspace

run in Azure Cloud shell: https://docs.microsoft.com/en-us/azure/cloud-shell/overview
or on a machine with Azure Powershell modules installed
#>


# Install the Resource Graph module from PowerShell Gallery
#https://docs.microsoft.com/en-us/azure/governance/resource-graph/first-query-powershell
Install-Module -Name Az.ResourceGraph

#kusto regex https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/extractfunction
# + https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/re2
Search-AzGraph -Query "Resources |
extend managedResourceGroupId=extract('resourceGroups/([\\w\\W]*)', 1, tostring(properties.managedResourceGroupId)) |
project name, type, managedResourceGroupId | 
     where type =~ 'microsoft.databricks/workspaces'"