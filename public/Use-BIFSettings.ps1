<#
	.SYNOPSIS
        Läser in konfigurationsdata.

	.DESCRIPTION

    .PARAMETER Path
        Anger en sökväg till konfigurationsfilen

	.EXAMPLE
        Use-BIFSettings

        Läser in konfigurationsdata från standardsökvägen

	.EXAMPLE
        Use-BIFSettings -Path \\fileserver\share$\BIF\

        Läser in konfigurationsdata från konfigurationsfil lagrad i \\fileserver\share$\BIF\

	.NOTES

	.LINK
#>
Function Use-BIFSettings {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [string]$Path
    )

    # Generated with New-FortikaPSFunction

    BEGIN {
		# If -debug is set, change $DebugPreference so that output is a little less annoying.
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If ($PSBoundParameters['Debug']) {
			$DebugPreference = 'Continue'
		}

        # This whole thing needs looking at...


        $ModuleRoot = Split-Path -Path ${PSScriptRoot} -Parent

        Write-Debug "ModuleRoot: $ModuleRoot"

        if(-not $Path) {
            # if $Path are unspecified, assume we shall go look for the config in module directory
            #$ConfigStoragePath = Split-Path $PSCmdlet.MyInvocation.PSScriptRoot -Parent
            $ConfigStoragePath = Join-Path -Path $ModuleRoot -ChildPath 'Posh-BIF.Utils.conf'
        } else {

        }

        Write-Debug "ConfigStoragePath: $ConfigStoragePath"

        if($(Test-Path -Path $ConfigStoragePath)) {

            Write-Verbose "Reading config data from $ConfigStoragePath"

            try {
                $script:EnvironmentConfig = Import-Clixml -Path $ConfigStoragePath -ErrorAction stop

                # store where we loaded base config from.
                $script:EnvironmentConfigPath = $ConfigStoragePath

                if($script:EnvironmentConfig) {
                    # test access to configuration files
                    $script:EnvironmentConfig.keys  | ForEach-Object {

                        $confname = $_
                        $conf = $script:EnvironmentConfig[$confname]

                        if(-Not $(Test-Path -Path $conf) ) {
                            Write-Warning ("Could not find configuration file `"{0}`". Check that the file exist and you have access rights to it." -f $conf)
                        } else {
                            # http://stackoverflow.com/questions/22943289/powershell-what-is-the-best-way-to-check-whether-the-current-user-has-permissio
                            try {
                                [io.file]::OpenWrite($conf).close()
                            }
                            Catch {
                                Write-Warning "You don't seem to have write access to configuration file `"$conf`". Check that the file exist and you have access rights to it."
                            }
                        }
                    }
                }
            }
            catch {
                Write-Warning ("Unable to load base configuration from $ConfigStoragePath`r`n{0}" -f $($_.Exception.Message))
            }
        } else {
            Write-Warning "Can't find base config! Use Initialize-BIFSettings to create a base config and then use Use-BIFSettings to load the settings or reload the module."
        }
    }

    PROCESS {

    }

    END {

    }
}
