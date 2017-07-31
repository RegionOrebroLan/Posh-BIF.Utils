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
        <#
        [Parameter(Mandatory=$True)]
        [ValidateSet('Prod','Test','QA')]
        [string]$Environment
        #>
    )
    DynamicParam {
        $RuntimeParameterDictionary = _New-DynamicValidateSetParam -ParameterName "Environment" `
                                                                   -ParameterType [DynParamQuotedString] `
                                                                   -Mandatory $True `
                                                                   -FillValuesWith "_OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames"

        return $RuntimeParameterDictionary
    }

    BEGIN {
        if(-Not $script:EnvironmentConfig) {
            Throw "Global Environment config is not set! Is the module properly loaded? use Use-BIFSettings to re-read configuration data."
        }

        $Environment = $PSBoundParameters["Environment"].OriginalString

        try {
            $EnvConfigFile = $script:EnvironmentConfig[$Environment]
            # use resolve-path to get the full path of file.
            # on .NET core there seems to be problem with saving to a relative path
            $EnvConfigFile = (Resolve-Path -Path $EnvConfigFile).Path

            [xml]$ConfigData = Get-Content $EnvConfigFile -ErrorAction Stop
        }
        catch {
            Throw "Could not load configuration from `"$EnvConfigFile`". Make sure the file exists and your account has access to it, or that EnvironmentConfig is defined, is the module loaded properly?"
        }

        $TS = (Get-date).ToString('yyyyMMdd')



        $CustomerUserACLData = ""

        # here strings can't be indented
        $CustomerUserACLDataTemplate = @"
`t`t`t<!-- %CUSTOMERNAME%: %CAREPROVIDERNAME% -->
`t`t`t<attribute name="urn:sambi:names:attribute:careProviderHsaId" value="%CAREPROVIDERHSAID%"/>
"@

        foreach($Customer in $ConfigData.OLLBIF.Customers.Customer) {

            # check if the customer is to be excluded by flag excludeFromUserACL
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


                # The defined systems can have their own care providers
                # Two loops should not really be neccessary. It's probably possible to just loop $Customer.Systems.system.careproficers.careprovider
                #   to get all careproviders that's attached to all underlying systems for a particular customer.
                # But since the flag excludeFromUserACL might be used the code gets a little easier to read if each underlying care provider is looped
                # separately
                foreach($System in $Customer.Systems.system) {

                    # check if specified care provider shall be included (not excluded)
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

        # create a directory to store the files, and a backup directory
        $OutputDirectory = join-path -path $(split-path -path $script:EnvironmentConfig[$Environment]) -ChildPath "UserRules"
        _New-DirectoryWithTest -Name $OutputDirectory

        $BackupDirectory = Join-Path -Path $OutputDirectory -ChildPath "Backup"
        _New-DirectoryWithTest -Name $BackupDirectory


        $OutputFileName = Join-Path -Path $OutputDirectory -ChildPath "regler_default_local_OLL-$($Configdata.OLLBIF.Environment.Name)-$($Configdata.OLLBIF.Environment.Version)_$($TS).xml"


        # get the template for user rules.
        # In the template, variable %CAREGIVERXMLDATA% must be defined where the created rules, stored in $CustomerUserACLData, should be inserted.
        # _Expand-VariablesInString  does a replace on all %CAREGIVERXMLDATA% with the data in $CustomerUserACLData
        Get-Content $ConfigData.OLLBIF.Environment.UserAccessTemplate -Encoding UTF8 -raw | `
             _Expand-VariablesInString -VariableMappings @{ CAREGIVERXMLDATA = $CustomerUserACLData } | `
             Out-File -FilePath $OutputFileName -Encoding utf8


        Write-Verbose "Created $OutputFileName"
    }

    PROCESS {
    }

    END {
    }
}
