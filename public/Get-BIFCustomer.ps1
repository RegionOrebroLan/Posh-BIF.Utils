﻿<#
    .SYNOPSIS
        Hämtar information om en registrerad kund i lokala säkerhetstjänsterna.

    .DESCRIPTION
        Hämtar information om en registrerad kund i lokala säkerhetstjänsterna.

    .PARAMETER CustomerName
        Anger vilken kund information skall hämtas för.
        Om inte ShortName eller denna parameter anges hämtas information om alla kunder.

    .PARAMETER ShortName
        Anger kort-namn på den kund som skall hämtas.
        Om inte CustomerName eller denna parameter anges hämtas information om alla kunder.

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
    [cmdletBinding(DefaultParameterSetName='CustomerName')]
    Param(
        [Parameter(Mandatory=$False
                  ,ValueFromPipelineByPropertyName=$True
                  ,ParameterSetName="CustomerName"
        )]
        [string]$CustomerName

        ,[Parameter(Mandatory=$False
                  ,ValueFromPipelineByPropertyName=$True
                  ,ParameterSetName="ShortName"
        )]
        [string]$ShortName

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
        # If -debug is set, change $DebugPreference so that output is a little less annoying.
        #    http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

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

            if($CustomerName) {
                $ConfigData.OLLBIF.Customers.Customer | ? { $_.Name -eq $CustomerName }
            } elseif($ShortName) {
                $ConfigData.OLLBIF.Customers.Customer | ? { $_.ShortName -eq $ShortName }
            } else {
                $ConfigData.OLLBIF.Customers.Customer | select Name, ShortName
            }
    }

    END {
    }
}
