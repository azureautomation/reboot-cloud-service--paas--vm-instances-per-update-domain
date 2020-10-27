Reboot Cloud Service (PaaS) VM Instances Per Update Domain
==========================================================

            

 



 
 
Reboots cloud service instances per update domain. It uses powershell workflow to update all instances in a domain in parallel. This runbook is useful for scenarios where one needs to reboot their service instances while keeping the service running. If the
 service is properly 'partitioned' per update domains, this runbook will reboot one update domain at a time.

 


**Requirements:**


Create the following connection Assets:


A. if using AAD approach for Azure connection:


- 'AzureAutomationAccount': credential asset (used for AAD connection: see https://azure.microsoft.com/en-us/documentation/articles/automation-credentials/ for more information'


- 'AzureSubscriptionId': variable containing the Azure subscription ID.


- 'CloudServiceName': variable containing the name of the cloud service to reboot


 


B. if using Management Certificate approach for Azure connection:


- Certificate credential asset - upload a management certificate to your Azure Automation account - see https://azure.microsoft.com/en-us/documentation/articles/automation-certificates/


- 'AzureSubscriptionName': variable containing the Azure subscription name.


- 'AzureSubscriptionId': variable containing the Azure subscription ID.


- 'CertificateName': variable containing the name of the certificate credential asset.


- 'CloudServiceName': variable containing the name of the cloud service to reboot


 


 


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
