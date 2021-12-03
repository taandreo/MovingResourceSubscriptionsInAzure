<#
 .SYNOPSIS
    This script moves all resources from a resource group to a new subscription.

 .DESCRIPTION
    This script moves all resources from a resource group to a new subscription.

 .EXAMPLE
     ./devops/MoveResource.ps1 -ResourceGroupName ResourceGroupWhere -NewSubscriptionId "new-subscription-id" -CurrentSubscriptionId "current-sub-id"
 
 .PARAMETER NewSubscriptionId
    The new subcription id to move resources

 .PARAMETER CurrentSubscriptionId
    Current subscription id.

 .PARAMETER ResourceGroupName
    Resource Goup where the resources are located. If the resource group don't exist in the new subscription it will be created.
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Please specify the new subcription id to move resources")]
    [String]$NewSubscriptionId,
    
    [Parameter(Mandatory = $true, HelpMessage = "Please specify current subscription id")]
    [String]$CurrentSubscriptionId,

    [Parameter(Mandatory = $true, HelpMessage = "Resource Group to Move the resources ")]
    [String]$ResourceGroupName
)


# Resoruces Type to move. Only this resource types will be moved from the $ResourceGroupName to the new subscription
$resourcesTypeList = @(
    "Microsoft.Storage/storageAccounts"
)

Write-Host "Setting context for subId $CurrentSubscriptionId ..." 
Set-AzContext -SubscriptionId $currentSubscriptionId | Out-Null

Write-Host ("Getting all resources from resource group {0} ..." -f $ResourceGroupName)
$resources = Get-AzResource -ResourceGroupName $ResourceGroupName | Where-Object { $_.ResourceType -in $resourcesTypeList }

if ((az group exists --name $resourceGroupName --subscription $newSubscriptionId) -eq 'false') {
   Write-Host "Creating $ResourceGroupName in the NewSubscription $NewSubscriptionId"
   $Location = (Get-AzResourceGroup -Name $ResourceGroupName).Location
   az group create --name $resourceGroupName --subscription $newSubscriptionId --location $Location | Out-Null
}

foreach($resource in $resources){
   $ResourceId = $resource.ResourceId
   Write-Host "Moving $ResourceId ..."
   Move-AzResource -DestinationResourceGroupName $resourceGroupName -ResourceId $ResourceId -DestinationSubscriptionId $newSubscriptionId -force | Out-Null
    
   if ($?) {
       Write-Host ("Resource {0} moved to new subscription >> {1}" -f $ResourceId, $newSubscriptionId) -ForegroundColor Green
   }
   else {
       Write-Host ($_.Exception.message)
       Write-Host ("Moving Resource {0} to new subscription failed >> {1}" -f $ResourceId, $newSubscriptionId) -ForegroundColor Red
       return
   }  
}

Write-Host "Execution Finished."