<#
    .SYNOPSIS
        Kontrollerar om en viss kund finns registrerad.

    .DESCRIPTION
        Kontrollerar om en viss kund finns registrerad.

    .PARAMETER CustomerName
        Anger vilken kund informationen skall hämtas för.

    .PARAMETER Environment
        Anger den driftmiljö som konfigurationen skall hämtas för.

    .EXAMPLE
        Test-BIFCustomer -CustomerName "Region Örebro län" -Environment Prod

    .NOTES

    .LINK


#>
Function Test-BIFCustomer {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$CustomerName

        <#
        ,[Parameter(Mandatory=$True)]
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
            Throw "Global Environment config is not set! Is the module properly loaded?"
        }
        
        try {
            $EnvConfigFile = $script:EnvironmentConfig[$Environment]
            [xml]$ConfigData = Get-Content $EnvConfigFile -ErrorAction Stop
        }
        catch {
            Throw "Could not load configuration from `"$EnvConfigFile`". Make sure the file exists and your account has access to it, or that EnvironmentConfig is defined, is the module loaded properly?"
        }
    }

    PROCESS {

        if( $($ConfigData.OLLBIF.Customers.customer | ? { $_.Name -eq $CustomerName }) ) {
            return $True
        } else {
            return $False
        }
    }

    END {
    }
}

