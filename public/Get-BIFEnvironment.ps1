<#
    .SYNOPSIS
        Hämtar konfigurationsinformation om registrerade miljöer.

    .DESCRIPTION
        Hämtar konfigurationsinformation om registrerade miljöer.

    .PARAMETER Environment
        Anger vilken miljö konfiguration skall visas för.
        Kan uteslutas för att få alla registrerade miljöer.

    .EXAMPLE
        Get-BIFEnvironment

        Visar information om alla registrerade miljöer

    .EXAMPLE
        Get-BIFEnvironment -Environment Test

        Visar information om miljön Test

    .NOTES

    .LINK
#>
Function Get-BIFEnvironment {
    [cmdletBinding()]
    Param(
    )
    DynamicParam {
        $RuntimeParameterDictionary = _New-DynamicValidateSetParam -ParameterName "Environment" `
                                                                   -ParameterType [DynParamQuotedString] `
                                                                   -Mandatory $False `
                                                                   -FillValuesWith "_OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames"

        return $RuntimeParameterDictionary
    }

    # Generated with New-FortikaPSFunction -Name Get-BIFEnvironment -Params @{Environment=@{Type="string"; Parameter=@{Mandatory=$False}}} | Set-Clipboard

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

        if($Environment) {
          $EnvArray = $Environment
        } else {
          # not really an array returned from keys, but whatever...
          $EnvArray = $script:EnvironmentConfig.keys
        }
    }

    PROCESS {

      #foreach($env in $script:EnvironmentConfig.keys) {
      foreach($env in $EnvArray) {

          $EnvName = $env
          $EnvConfigFile = $EnvConfigFile = $script:EnvironmentConfig[$env]

          try {
              # use resolve-path to get the full path of file.
              # on .NET core there seems to be problem with saving to a relative path
              $EnvConfigFile = (Resolve-Path -Path $EnvConfigFile -ErrorAction stop).Path

              [xml]$ConfigData = Get-Content $EnvConfigFile -ErrorAction Stop
          }
          catch {
              #Throw "Could not load configuration from `"{0}`". Make sure the file exists and your account has access to it, or that EnvironmentConfig is defined, is the module loaded properly?" -f $EnvName
              Write-Warning "Could not load configuration from `"${EnvConfigFile}`". Make sure the file exists and your account has access to it. Use Set-BIFEnvironment to point ${EnvName} to another config file."
          }

          New-Object -TypeName psobject -Property @{
              Environment = $EnvName;
              ConfigFile = $EnvConfigFile;
              Version = $ConfigData.OLLBIF.Environment.Version;
              UserAccessTemplate = $ConfigData.OLLBIF.Environment.UserAccessTemplate;
              SystemAccessTemplate = $ConfigData.OLLBIF.Environment.SystemAccessTemplate;
          }
      }
    }

    END {

    }
}
