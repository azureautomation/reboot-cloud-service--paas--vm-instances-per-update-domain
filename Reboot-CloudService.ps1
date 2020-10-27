<#
    .SYNOPSIS
		Reboots Cloud Service instances per update domain.
	
	.DESCRIPTION
        Reboots Cloud Service instances per update domain. It uses powershell workflow to update all instances in a domain in parallel. This runbook is useful for 
		scenarios where one needs to reboot their service instances while keeping the service running. If the service is properly "partitioned" per update domains, 
		this runbook will reboot one update domain at a time.
		
		Requirements:
		
		Create the following connection Assets:
		 
		  A. if using AAD approach for Azure connection:
		  - "AzureAutomationAccount": credential asset (used for AAD connection: see https://azure.microsoft.com/en-us/documentation/articles/automation-credentials/ for more information"
		  - "AzureSubscriptionId": variable containing the Azure subscription ID.
		  - "CloudServiceName": variable containing the name of the cloud service to reboot
		  
		  B. if using Management Certificate approach for Azure connection:
		  - Certificate credential asset - upload a management certificate to your Azure Automation account - see https://azure.microsoft.com/en-us/documentation/articles/automation-certificates/
		  - "AzureSubscriptionName": variable containing the Azure subscription name.
		  - "AzureSubscriptionId": variable containing the Azure subscription ID.
		  - "CertificateName": variable containing the name of the certificate credential asset.
		  - "CloudServiceName": variable containing the name of the cloud service to reboot

    .NOTES
        AUTHOR: Gustavo Lima
        LASTEDIT: Dec 10, 2015
		
#>
workflow Reboot-CloudService
{
	<#
	----------------------------------------------------------------------------------------------
	-- CONNECT VIA AAD: Uncomment below if AAD is desired ----------------------------------------
	----------------------------------------------------------------------------------------------
	#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
    $CredentialAssetName = 'AzureAutomationAccount'
	
	#Get the credential with the above name from the Automation Asset store
    $Cred = Get-AutomationPSCredential -Name $CredentialAssetName
    if(!$Cred) {
        Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
    }

    #Connect to your Azure Account
    $Account = Add-AzureAccount -Credential $Cred
    if(!$Account) {
        Throw "Could not authenticate to Azure using the credential asset '${CredentialAssetName}'. Make sure the user name and password are correct."
    }
	#>
	
	<# 
	----------------------------------------------------------------------------------------------
	-- CONNECT VIA Azure Management Certificate: comment below section out if AAD is used instead
	----------------------------------------------------------------------------------------------
	#>
	#The subscriptionId to connect to.
	$azureSubscriptionName = Get-AutomationVariable -Name "AzureSubscriptionName"
	$azureSubscriptionId =  Get-AutomationVariable -Name "AzureSubscriptionId"
	# The management certificate		
    $certificateName = Get-AutomationVariable -Name "CertificateName" 
    $certificate = Get-AutomationCertificate -Name $certificateName  
	#Set the management certificate.
	Set-AzureSubscription -SubscriptionName $azureSubscriptionName -SubscriptionId $azureSubscriptionId -Certificate $certificate
	Write-Output "Set management certificate $certificateName for subscription '$azureSubscriptionName'"
	<# ------------------------------------------------------------------------------------------ #>
	
	
	#Select the subscription 
	Select-AzureSubscription -SubscriptionId $AzureSubscriptionId
	
	# The name of the Cloud Service
	$cloudServiceName = Get-AutomationVariable -Name 'CloudServiceName'
	
	# Retrieve all role instances for the cloud service	
	$roleInstances = Get-AzureRole -ServiceName $cloudServiceName -Slot Production -InstanceDetails
	Write-Output "Retrieved all role instances for cloud service: $cloudServiceName. Number of instances: " + $roleInstances.Count
	
	# Group instances per update domain
	$roleInstanceGroups = $roleInstances | Group-Object -AsHashTable -AsString -Property InstanceUpgradeDomain
	Write-Output "Number of update domains found: " + $roleInstanceGroups.Keys.Count
	
	# Visit each update domain
	foreach ($key in $roleInstanceGroups.Keys)
	{
		$count = $perDomainInstances.Count;
		Write-Output "Rebooting $count instances in domain $key"	
		
		$perDomainInstances = $roleInstanceGroups.Get_Item($key)
		
		foreach -parallel($instance in $perDomainInstances)
		{
			$instanceName = $instance.InstanceName
			Write-Output "Rebooting instance $instanceName"
				
			Reset-AzureRoleInstance -ServiceName $cloudServiceName -Slot Production -InstanceName $instanceName -Reboot -ErrorAction Stop
		} 
	}
}