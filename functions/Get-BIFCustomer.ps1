<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER xxxx

    .EXAMPLE

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
