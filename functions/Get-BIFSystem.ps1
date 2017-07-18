<#
    .SYNOPSIS
        Hämtar information om ett registrerat system som är kopplat till säkerhetstjänsterna.

    .DESCRIPTION
        Hämtar information om ett registrerat system som är kopplat till säkerhetstjänsterna.
        För att få upp vilka kunder som finns registrerade, använd cmdlet Get-BIFCustomer.

    .PARAMETER CustomerName
        Anger för vilken kund systemet tillhör.

    .PARAMETER SystemName
        Anger namn på systemet.

    .PARAMETER Environment
        Anger den driftmiljö som konfigurationen skall hämtas för.

    .EXAMPLE

    .NOTES

    .LINK

#>
Function Get-BIFSystem {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$CustomerName,

        [Parameter(Mandatory=$False)]
        [string]$SystemName

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
            [xml]$ConfigData = Get-Content $EnvConfigFile -ErrorAction Stop
        }
        catch {
            Throw "Could not load configuration from `"$EnvConfigFile`". Make sure the file exists and your account has access to it, or that EnvironmentConfig is defined, is the module loaded properly?"
        }
    }

    PROCESS {
        if(-Not $SystemName) {
            $ConfigData.OLLBIF.Customers.customer | ? { $_.Name -eq $CustomerName } | `
                select -ExpandProperty Systems | `
                select -ExpandProperty system
        } else {
            $ConfigData.OLLBIF.Customers.customer | ? { $_.Name -eq $CustomerName } | `
                select -ExpandProperty Systems | `
                select -ExpandProperty system | ? { $_.Name -eq $SystemName }
        }
    }

    END {
    }
}
