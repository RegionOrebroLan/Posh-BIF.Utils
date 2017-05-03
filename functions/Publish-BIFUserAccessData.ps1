<#
    .SYNOPSIS
        Skapar konfiguration för användar-access.

    .DESCRIPTION
        Skapar konfiguration för användar-access för angiven miljö.

    .PARAMETER Environment
        Anger den driftmiljö som konfigurationen skall skapas för.

    .EXAMPLE
        Publish-BIFUserAccessData -Environment Prod

    .NOTES

    .LINK

#>
Function Publish-BIFUserAccessData {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateSet('Prod','Test','QA')]
        [string]$Environment
    )


    try {
        [xml]$ConfigData = Get-Content $script:EnvironmentConfig[$Environment] -ErrorAction Stop
    }
    catch {
        Throw "Could not load configuration from `"$($script:EnvironmentConfig[$Environment])`". Make sure the file exists and your account has access to it."
    }

    $TS = (Get-date).ToString('yyyyMMdd')



    $CustomerUserACLData = ""

# Den här raden (en here-string) kan inte intenderas!
$CustomerUserACLDataTemplate = @"

`t`t`t<!-- %CUSTOMERNAME%: %CAREPROVIDERNAME% -->
`t`t`t<attribute name="urn:sambi:names:attribute:careProviderHsaId" value="%CAREPROVIDERHSAID%"/>
"@

    foreach($Customer in $ConfigData.OLLBIF.Customers.Customer) {

        # kolla om kunden skall exkluderas via flaggan excludeFromUserACL
        if(-Not $Customer.ExcludeFromUserACL) {

            foreach($Careprovider in $Customer.Careproviders.Careprovider) {

                if(-Not $Careprovider.excludeFromUserACL) {
                    $CustomerUserACLData += $CustomerUserACLDataTemplate | _Expand-VariablesInString -VariableMappings @{ 
                                                                CAREPROVIDERNAME = $Careprovider.name; 
                                                                CAREPROVIDERHSAID = $Careprovider.hsaid;
                                                                CUSTOMERNAME = $Customer.name;
                                                             }
                } else {
                    Write-Verbose "Excluding careprovider `"$($Careprovider.Name)`" from `"$($Customer.Name)`"."
                }
            }


            # De system som är definerade kan ha egna careproviders definerade.
            # Här hade man inte behövt 2 loopar egentligen, utan det skulle gå att endast loopa $Customer.Systems.system.careproviders.careprovider
            # för att få ut alla careproviders som sitter på alla underställda system till kunden.
            # Men eftersom flaggan excludeFromUserACL skall kunna användas så blir koden enklare om system och dess underställda careproviders
            # loopas ut var för sig.
            foreach($System in $Customer.Systems.system) {
                
                # kolla först så spec'ade careproviders inte skall exkluderas.
                if(-Not $System.careproviders.excludeFromUserACL -or $System.careproviders.excludeFromUserACL -eq 0) {

                    foreach($Careprovider in $System.Careproviders.careprovider) {


                        if(-Not $Careprovider.excludeFromUserACL -or $Careprovder.excludeFromUserACL -eq 0) {

                            $CustomerUserACLData += $CustomerUserACLDataTemplate | _Expand-VariablesInString -VariableMappings @{ 
                                                                        CAREPROVIDERNAME = $Careprovider.name; 
                                                                        CAREPROVIDERHSAID = $Careprovider.hsaid;
                                                                        CUSTOMERNAME = "$($Customer.name) ($($System.Name))";
                                                                     }
                        }
                    }
                }

            }


            $CustomerUserACLData += "`r`n"
        }
    }
    

    # Skapa katalog där filerna kommer skrivas, samt backupkatalog
    $OutputDirectory = "$(split-path -path $script:EnvironmentConfig[$Environment])\UserRules"
    _New-DirectoryWithTest -Name $OutputDirectory

    $BackupDirectory = "$OutputDirectory\Backup"
    _New-DirectoryWithTest -Name $BackupDirectory


    $OutputFileName = "$($OutputDirectory)\regler_default_local_OLL-$($Configdata.OLLBIF.Environment.Name)-$($Configdata.OLLBIF.Environment.Version)_$($TS).xml"


    # hämta upp mallen för användarregler.
    # I mallen finns variabel %CAREGIVERXMLDATA% angiven där skapade reglerna som ligger i $CustomerUserACLData skall placeras.
    # _Expand-VariablesInString  gör en replace på alla %CAREGIVERXMLDATA% till datat i $CustomerUserACLData 
    Get-Content $ConfigData.OLLBIF.Environment.UserAccessTemplate -Encoding UTF8 -raw | `
         _Expand-VariablesInString -VariableMappings @{ CAREGIVERXMLDATA = $CustomerUserACLData } | `
         Out-File -FilePath $OutputFileName -Encoding utf8


    Write-Verbose "Created $OutputFileName"
}
