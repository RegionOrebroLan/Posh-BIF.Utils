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
        [string]$CustomerName,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Prod','Test','QA')]
        [string]$Environment
    )

    BEGIN {
    }

    PROCESS {
        try {
            [xml]$ConfigData = Get-Content $script:EnvironmentConfig[$Environment] -ErrorAction Stop
        }
        catch {
            Throw "Could not load configuration from `"$($script:EnvironmentConfig[$Environment])`". Make sure the file exists and your account has access to it."
        }

        if( $($ConfigData.OLLBIF.Customers.customer | ? { $_.Name -eq $CustomerName }) ) {
            return $True
        } else {
            return $False
        }
    }

    END {
    }
}

