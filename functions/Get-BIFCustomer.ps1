<#
    .SYNOPSIS
        Hämtar information om en registrerad kund i lokala säkerhetstjänsterna.

    .DESCRIPTION
        Hämtar information om en registrerad kund i lokala säkerhetstjänsterna.

    .PARAMETER CustomerName
        Anger vilken kund information skall hämtas för.
        Om denna parameter inte anges, hämtas information om alla kunder.

    .PARAMETER Environment
        Anger den driftmiljö som konfigurationen skall hämtas för.

    .EXAMPLE
        Get-BIFCustomer -Environment Prod

    .EXAMPLE
        Get-BIFCustomer -CustomerName "Region Örebro län" -Environment Prod

    .NOTES

    .LINK

#>
Function Get-BIFCustomer {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$False
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$CustomerName,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Prod','Test','QA')]
        [string]$Environment
    )

    BEGIN {
        try {
            [xml]$ConfigData = Get-Content $script:EnvironmentConfig[$Environment] -ErrorAction Stop
        }
        catch {
            Throw "Could not load configuration from `"$($script:EnvironmentConfig[$Environment])`". Make sure the file exists and your account has access to it."
        }
    }

    PROCESS {
        if(-Not $CustomerName) {
            $ConfigData.OLLBIF.Customers.Customer | select Name, ShortName
        } else {
            $ConfigData.OLLBIF.Customers.Customer | ? { $_.Name -eq $CustomerName }
        }
    }

    END {
    }
}
