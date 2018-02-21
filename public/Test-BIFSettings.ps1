<#
    .SYNOPSIS
        Testar om konfigurationsinformation är giltig

    .DESCRIPTION
        
    .PARAMETER Environment

    .PARAMETER EnvironmentConfigFile

    .EXAMPLE
        Test-BIFSettings

    .NOTES
        
    .LINK
        
#>
Function Test-BIFSettings {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True
                  ,ParameterSetName="ConfFile")]
        [string]$EnvironmentConfigFile
    )
    DynamicParam {
        $RuntimeParameterDictionary = _New-DynamicValidateSetParam -ParameterName "Environment" `
                                                                   -ParameterType [DynParamQuotedString] `
                                                                   -Mandatory $True `
                                                                   -ExtraParameterProperties @{ParameterSetName='Env'} `
                                                                   -FillValuesWith "_OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames"

        return $RuntimeParameterDictionary
    }

    # Generated with New-FortikaPSFunction -Name Test-BIFSettings -Synopsis "Testar om konfigurationsinformation är giltig" -Params @{Environment="string"; EnvironmentConfigFile="string"}

    BEGIN {
        # If -debug is set, change $DebugPreference so that output is a little less annoying.
        #    http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        $Environment = $PSBoundParameters["Environment"].OriginalString

        if($Environment) {
            $EnvironmentConfigFile = $script:EnvironmentConfig[$Environment]            
        }
    }

    PROCESS {

        if($EnvironmentConfigFile) {
        
            if(-not $(Test-Path -Path $EnvironmentConfigFile) ) {
                Write-Debug "$($PSCmdlet.MyInvocation.MyCommand.Name): $EnvironmentConfigFile does not exist!"
                return $False
            }

            try {
                $EnvironmentConfigFile = Resolve-Path -Path $EnvironmentConfigFile -ErrorAction stop
                [xml]$Confdata = Get-Content -Path $EnvironmentConfigFile -ErrorAction stop

            } catch {
                Write-Debug "$($PSCmdlet.MyInvocation.MyCommand.Name): $($_.Exception.Message)"
                return $False
            }

            try {
                [io.file]::OpenWrite($EnvironmentConfigFile).close()

                Write-Debug "$($PSCmdlet.MyInvocation.MyCommand.Name): $EnvironmentConfigFile is writable"
            }
            Catch {
                Write-Debug "$($PSCmdlet.MyInvocation.MyCommand.Name): $EnvironmentConfigFile does not seem to be writable!"
                return $False
            }

            $ModuleRoot = Split-Path -Path ${PSScriptRoot} -Parent
            Write-Debug "$($PSCmdlet.MyInvocation.MyCommand.Name): ModuleRoot: $ModuleRoot"

            # using IO.Path::combine instead of join-path 
            # https://stackoverflow.com/questions/41768933/powershell-to-generate-file-paths-correctly-in-windows-and-unix#41769083
            $SchemaPath = [System.IO.Path]::Combine($ModuleRoot,"res","config.xsd")

            if( $(Test-Path -Path $SchemaPath) ) {
                if(-not $(Test-Xml -Path $EnvironmentConfigFile -SchemaPath $SchemaPath) ) {
                    Write-Debug "$($PSCmdlet.MyInvocation.MyCommand.Name): $($Script:XmlValidationErrorLog -join "`n")"
                    return $False
                }
            } else {
                Write-Warning "Could not find xml schema file `"${SchemaPath}`". Please check where the file has snuck off to. We're going to assume $EnvironmentConfigFile is correctly formatted..."
            }




            return $True

        } else {
            return $False
        }
    }

    END {
    }
}