<#
    .SYNOPSIS
        Ändrar inställningar för en viss miljö

    .DESCRIPTION

    .PARAMETER Environment

    .PARAMETER SystemAccessTemplate

    .PARAMETER ConfigFile

    .PARAMETER Version

    .PARAMETER UserAccessTemplate

    .PARAMETER Name

    .EXAMPLE
        Set-BIFEnvironment

    .NOTES

    .LINK

#>
Function Set-BIFEnvironment {
    [cmdletBinding(SupportShouldProcess=$True)]
    Param(
      [Parameter(Mandatory=$False)]
      [string]$SystemAccessTemplate

      ,[Parameter(Mandatory=$False)]
      [String]$ConfigFile

      ,[Parameter(Mandatory=$False)]
      [string]$Version

      ,[Parameter(Mandatory=$False)]
      [string]$UserAccessTemplate

      ,[Parameter(Mandatory=$False)]
      [string]$Name
    )
    DynamicParam {
        $RuntimeParameterDictionary = _New-DynamicValidateSetParam -ParameterName "Environment" `
                                                                   -ParameterType [DynParamQuotedString] `
                                                                   -Mandatory $True `
                                                                   -FillValuesWith "_OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames"

        return $RuntimeParameterDictionary
    }
    # Generated with New-FortikaPSFunction -Name Set-BIFEnvironment -Params @{Environment="string"; Name="string"; SystemAccessTemplate="string"; Version="string"; ConfigFile="String"; UserAccessTemplate="string"} -Synopsis "Ändrar inställningar för en viss miljö" -Path ./Posh-BIF.Utils/functions/Set-BIFEnvironment.ps1

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

    }

    END {

    }
}
