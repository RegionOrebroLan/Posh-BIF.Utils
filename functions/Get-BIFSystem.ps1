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
        $Environment = $PSBoundParameters["Environment"].OriginalString

        try {
            [xml]$ConfigData = Get-Content $script:EnvironmentConfig[$Environment] -ErrorAction Stop
        }
        catch {
            Throw "Could not load configuration from `"$($script:EnvironmentConfig[$Environment])`". Make sure the file exists and your account has access to it."
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
