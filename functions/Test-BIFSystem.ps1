<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER xxxx

    .EXAMPLE

    .NOTES

    .LINK

#>
Function Test-BIFSystem {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$CustomerName,

        [Parameter(Mandatory=$True)]
        [string]$SystemName,

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
        $System = $ConfigData.OLLBIF.Customers.customer | ? { $_.Name -eq $CustomerName } | select -ExpandProperty Systems | select -ExpandProperty system | ? { $_.Name -eq $SystemName }

        if( $system ) {
            return $True
        } else {
            return $False
        }
    }

    END {
    }
}
