<#
    .SYNOPSIS
        Raderar konfiguration för en miljö

    .DESCRIPTION

    .PARAMETER Environment
      Anger namn på den miljö som skall raderas

    .EXAMPLE
        Remove-BIFEnvironment

    .NOTES

    .LINK

#>
Function Remove-BIFEnvironment {
    [cmdletBinding(ConfirmImpact="High"
                  ,SupportsShouldProcess=$True)]
    Param(
    )
    DynamicParam {
        $RuntimeParameterDictionary = _New-DynamicValidateSetParam -ParameterName "Environment" `
                                                                   -ParameterType [DynParamQuotedString] `
                                                                   -Mandatory $True `
                                                                   -FillValuesWith "_OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames"

        return $RuntimeParameterDictionary
    }

    # Generated with New-FortikaPSFunction -Name Remove-BIFEnvironment -Params @{Environment="string"} -Path ./Posh-BIF.Utils/functions/Remove-BIFEnvironment.ps1 -Synopsis "Raderar konfiguration för en miljö"

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
            # use resolve-path to get the full path of file.
            # on .NET core there seems to be problem with saving to a relative path
            $EnvConfigFile = (Resolve-Path -Path $EnvConfigFile).Path

            [xml]$ConfigData = Get-Content $EnvConfigFile -ErrorAction Stop
        }
        catch {
            Throw "Could not load configuration from `"$EnvConfigFile`". Make sure the file exists and your account has access to it, or that EnvironmentConfig is defined, is the module loaded properly?"
        }
    }

    PROCESS {
      if($PSCmdlet.ShouldProcess("$Environment","Remove")) {
        $script:EnvironmentConfig.Remove($Environment)

        #TODO: Skriv ut fil till den path som den laddats från. Skulle behöva en parameter från vilken fil config'en har laddats från. Utöka $script:EnvironmentConfig med något som pekar ut sökvägen.
        #$script:EnvironmentConfig | Export-Clixml -Path ....

      }
    }

    END {

    }
}
