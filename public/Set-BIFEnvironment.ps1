<#
    .SYNOPSIS
        Ändrar inställningar för en viss miljö

    .DESCRIPTION
      Ändrar inställningar för en viss miljö

    .PARAMETER Environment
      Anger vilken miljö som parametrar skall ändras för.

    .PARAMETER SystemAccessTemplate
      Anger sökväg till mall för systemregler.

    .PARAMETER UserAccessTemplate
      Anger sökväg till mall för användarregler.

    .PARAMETER ConfigFile
      Anger sökväg till konfigurationsfil.
      Om filen som pekas ut redan finns skrivs inte aktuell konfig data dit, utan filen börjar direkt användas.

    .PARAMETER Version
      Anger version på miljön.

    .PARAMETER Name
      Anger namn på miljön. Om parametern spec'as ändras namnet på miljön.

    .EXAMPLE
        Set-BIFEnvironment -Environment Test -Version "2.5"

    .EXAMPLE
        Set-BIFEnvironment -Environment Test -Name "Stage"

        Ändrar namn på miljön Test till Stage

    .NOTES

    .LINK

#>
Function Set-BIFEnvironment {
    [cmdletBinding(SupportsShouldProcess=$True
                  ,ConfirmImpact='High')]
    Param(
      [Parameter(Mandatory=$False)]
      [string]$SystemAccessTemplate

      ,[Parameter(Mandatory=$False)]
      [string]$UserAccessTemplate

      ,[Parameter(Mandatory=$False)]
      [String]$ConfigFile

      ,[Parameter(Mandatory=$False)]
      [string]$Version

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
            # use resolve-path to get the full path of file.
            # on .NET core there seems to be problem with saving to a relative path
            $EnvConfigFile = (Resolve-Path -Path $EnvConfigFile -ErrorAction stop).Path

            [xml]$ConfigData = Get-Content $EnvConfigFile -ErrorAction Stop
        }
        catch {           
            # if there was an error loading config file, allow to specify a new one with param ConfigFile
            # this is not the prettyest...
            $ConfigLoadError = $True
            if($ConfigFile) {
            } else {
                Throw "Could not load configuration from `"$EnvConfigFile`". Make sure the file exists and your account has access to it, or that EnvironmentConfig is defined, is the module loaded properly? Use `"Set-BIFEnvironment -Environment $Environment -ConfigFile <new config>`" to specify another configuration file."
            }
        }
    }
    PROCESS {
        if($ConfigFile) {
            try {
                $EnvConfigFile = (resolve-path -path $ConfigFile -ErrorAction stop).Path

                # if specified file exist, set it.
                if( $(Test-Path -Path $EnvConfigFile) ) {

                    Write-Verbose "$EnvConfigFile already exists. Going to try and use that..."

                    # if the specidied file exist, then test if it's valid                   
                    if( $(Test-BIFSettings -EnvironmentConfigFile $EnvConfigFile) ) {
                    
                        Write-Debug "$EnvConfigFile passed validation check"

                        $script:EnvironmentConfig[$Environment] = $EnvConfigFile

                        # load $configdata from newly specified config file.
                        # Because we might have more options specified on cmdline which needs to go into the file.
                        [xml]$ConfigData = Get-Content $EnvConfigFile -ErrorAction Stop

                        # write base config
                        try {
                            $script:EnvironmentConfig | Export-Clixml -Path  $script:EnvironmentConfigPath -ErrorAction Stop
                        }
                        catch {
                            Throw "Could not write base config to {0}`r`n{1}" -f  $script:EnvironmentConfigPath, $_.Exception.Message
                        }


                    } else {
                        Throw "Config `"{0}`" does not seem to be valid!" -f $EnvConfigFile
                    }

                } else {
                    #TODO: Initialize-BIFEnvironmentConfig ?? internal function only??
                }
            }
            catch {
                Throw $_.Exception.Message
            }
        }

        # if we had specified a new (valid) config file or there was NOT an error loading current config, then allow to set other params
        if($ConfigFile -or -not $ConfigLoadError) {

            #TODO: Add some validation to characters to that it's not something that can't be in XML
            if($Version) {
                $ConfigData.OLLBIF.Environment.Version = $Version

                Write-Debug "Version: $($ConfigData.OLLBIF.Environment.Version)"
            }

            if($SystemAccessTemplate) {
                if($(Test-Path -Path $SystemAccessTemplate)) {
                    $ConfigData.OLLBIF.Environment.SystemAccessTemplate = $SystemAccessTemplate
                } else {
                    Write-Warning "$SystemAccessTemplate does not exist."
                    if($PSCmdlet.ShouldProcess($SystemAccessTemplate,"Initialize")) {
                        #TODO: Initialize-BIFSystemAccessTemplate ?? internal function only?
                    }
                }
            }

            if($UserAccessTemplate) {
                if($(Test-Path -Path $UserAccessTemplate)) {
                    $ConfigData.OLLBIF.Environment.UserAccessTemplate = $UserAccessTemplate
                } else {
                    Write-Warning "$UserAccessTemplate does not exist."
                    if($PSCmdlet.ShouldProcess($UserAccessTemplate,"Initialize")) {
                        #TODO: Initialize-BIFUserAccessTemplate ?? internal function only?
                    }
                }
            }        
        }


    }

    END {        
      #Apparently xmldocument.Save(string filename) is not available on .NET core (OSX)
      if($PSEdition -eq "Core") {
        # we use a streamWriter instead.
        # this approach is probably available on full .NET as well
        $Configdata.Save([System.IO.StreamWriter]::new($EnvConfigFile))
      } else {
        $Configdata.save($EnvConfigFile)
      }
    }
}
