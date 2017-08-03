<#
    .SYNOPSIS
        Konverterar en konfigurationsfil till ett powershellscript.

    .DESCRIPTION

    .PARAMETER Environment
        Läser konfigurationen från angiven miljö.

    .PARAMETER CustomerName
        Konverterar endast konfiguration för angiven kund.

    .PARAMETER ApplyEnvironment
        För de kommandon som skapas sätts denna miljö.

    .PARAMETER Path
        Läser konfigurationen från angiven sökväg.

    .PARAMETER Data
        Läser konfigurationen från angiven sträng.
        Data till parametern kan även skickas in över pupeline.

    .EXAMPLE
        ConvertFrom-BIFConfigToScript -Environment Test

        Läser in konfiguration för miljö Test och skapar powershellkommandon för att skapa upp konfigurationen.

    .NOTES

    .LINK

#>
Function ConvertFrom-BIFConfigToScript {
    [cmdletBinding(DefaultParameterSetName='Data')]
    Param(
        [Parameter(Mandatory=$False
                  ,ParameterSetName='Path')]
        [string]$Path

        ,[Parameter(Mandatory=$False
                  ,ParameterSetName='Data'
                  ,ValueFromPipeline=$True)]
        [string]$Data

        ,[Parameter(Mandatory=$False)]
        [string]$CustomerName

        ,[Parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [string]$ApplyEnvironment
    )
    DynamicParam {
        $RuntimeParameterDictionary = _New-DynamicValidateSetParam -ParameterName "Environment" `
                                                                   -ParameterType [DynParamQuotedString] `
                                                                   -Mandatory $False `
                                                                   -ExtraParameterProperties @{ParameterSetName='Environment'} `
                                                                   -FillValuesWith "_OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames"

        return $RuntimeParameterDictionary
    }

    # Generated with New-FortikaPSFunction -name ConvertFrom-BIFConfigToScript -Params @{Environment="string"; Path="string"; ApplyEnvironment="string"; CustomerName="string"; }

    BEGIN {
        # If -debug is set, change $DebugPreference so that output is a little less annoying.
        #    http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        $Environment = $PSBoundParameters["Environment"].OriginalString

        if($Environment) {
            if(-Not $script:EnvironmentConfig) {
                Throw "Global Environment config is not set! Is the module properly loaded? use Use-BIFSettings to re-read configuration data."
            }

            try {
                $EnvConfigFile = $script:EnvironmentConfig[$Environment]
                [xml]$ConfigData = Get-Content $EnvConfigFile -ErrorAction Stop
            }
            catch {
                Throw "Could not load configuration from `"$EnvConfigFile`". Make sure the file exists and your account has access to it, or that EnvironmentConfig is defined, is the module loaded properly?"
            }
        }

        if($ApplyEnvironment) {
            $Environment = $ApplyEnvironment
        }
    }

    PROCESS {

        "Set-BIFEnvironment -Environment {0} -Version {1} -SystemAccessTemplate '{2}' -UserAccessTemplate '{3}'" -f $Environment, $ConfigData.OLLBIF.Environment.Version, $ConfigData.OLLBIF.Environment.SystemAccessTemplate, $ConfigData.OLLBIF.Environment.UserAccessTemplate

        foreach($customer in $ConfigData.OLLBIF.Customers.Customer) {

            $CustomerString = 'Add-BIFCustomer -Environment {0} -CustomerName "{1}"' -f $Environment, $customer.Name
            if($customer.ShortName) {
                $CustomerString += ' -ShortName "{0}"' -f $Customer.ShortName
            }

            foreach($system in $customer.Systems.System) {

                $SystemString = 'Add-BIFSystem -Environment "{0}" -CustomerName "{1}" -SystemName "{2}" -SystemHSAId "{3}"' -f $Environment, $customer.name, $system.name, $system.hsaid

                $SystemString

                #TODO: Handle exclude frm user ACL!

                foreach($careprovider in $system.Careproviders.careprovider) {

                    $CareproviderString = 'Add-BIFCareProvider -Environment "{0}" -CustomerName "{1}" -SystemHSAId "{2}" -CareproviderName "{3}" -CareProviderHSAId "{4}"' -f $Environment, $customer.name, $system.hsaid, $careprovider.name, $careprovider.hsaid

                    $CareproviderString
                }

            }

            foreach($careprovider in $customer.Careproviders.careprovider) {
                #TODO: Handle exclude frm user ACL!

                $CareproviderString = 'Add-BIFCareProvider -Environment "{0}" -CustomerName "{1}" -CareproviderName "{2}" -CareProviderHSAId "{3}"' -f $Environment, $customer.name, $careprovider.name, $careprovider.hsaid

                $CareproviderString
            }

            $CustomerString
        }

    }

    END {

    }
}
