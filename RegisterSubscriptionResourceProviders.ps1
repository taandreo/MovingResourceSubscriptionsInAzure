<#
 .SYNOPSIS
    Register resource providers for new subscription

 .DESCRIPTION
    This script register resource providers for new subscription when you are moving from one subscription to another. In order to use azure resources, you need to register provider first for that resource so it can be active (Just like importing namespace before using a library in programming). Script first takes the resource providers currently in use for current environment, then register those providers in new subscription

 .EXAMPLE
     ./devops/RegisterSubscriptionResourceProviders.ps1 -newSubscriptionId "new-subscription-id"

 .NOTES
     Registering some providers takes huge amount of time to complete due to azure, it simply hangs in "registering" state. This is not related with script, means you can simply restart the script again, so it can continue with the next provider in the list. Or simply remove the --wait parameter from command "az provider register" in script. This will moves to new provider in the list, once it sends the singal to azure to register provider.
 
 .PARAMETER newSubscriptionId
    The new subcription id to move resources

 .PARAMETER currentSubscriptionId
    Current subscription id. You dont need to set this if you are running it from devops repo manually, if you are using pipelines or automation, please set this accordingly.
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Please specify the new subcription id to move resources")]
    [String]$newSubscriptionId,
    
    # IMPORTANT : This parameter fills automatically by executing devops repo scripts manually in terminal, if you are going to use this script in CI/CD please fill this parameter accordingly 
    [Parameter(Mandatory = $false, HelpMessage = "Please specify current subscription id")]
    [String]$currentSubscriptionId
)

if (!$currentSubscriptionId) {
    $currentSubscriptionId = $environmentVariables.subscriptionId
}

Write-Host ("Current Subscription Id >> {0}" -f $currentSubscriptionId) -ForegroundColor Green
Write-Host ("New Subscription Id which resources providers will be created >> {0}" -f $newSubscriptionId) -ForegroundColor Magenta
Write-Host "---------------------------------" -ForegroundColor White

Write-Host ("Checking if all the resource provider exists in new subscription >> {0}" -f $newSubscriptionId) -ForegroundColor Cyan
Write-Host "---------------------------------" -ForegroundColor White

# Get all registered resource provider in this environment to register them in the new subscription if they are not registered already, operation will fail if the resource providers are not active in new subscription
$resourceProviderList = az provider list --subscription $currentSubscriptionId --query "[?registrationState=='Registered'].namespace" -o tsv

# Get all unregistered providers in target subscription so it can only register the differences
$targetUnRegisteredProviderList = az provider list --subscription $newSubscriptionId --query "[?registrationState=='NotRegistered'].namespace" -o tsv

foreach ($provider in $resourceProviderList) {

    if ($targetUnRegisteredProviderList.contains($provider)) {

        Write-Host ("Provider {0} is not registered. Registering..." -f $provider) -ForegroundColor Yellow

        # Registering provider in new subscription 
        az provider register --namespace $provider --subscription $newSubscriptionId --wait

        if ($?) {
            Write-Host ("New resource provider {0} created in subscription >> {1}" -f $provider, $newSubscriptionId) -ForegroundColor Green
        }
        else {
            Write-Host ("Resource provider {0} already exists in subscription >> {1}" -f $provider, $newSubscriptionId) -ForegroundColor Yellow
        }

        Write-Host "---------------------------------" -ForegroundColor White
    }
}
