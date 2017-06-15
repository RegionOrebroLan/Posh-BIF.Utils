<#
	.SYNOPSIS
        Initierar sökvägar olika driftmiljöers konfigurationsfiler.

	.DESCRIPTION
        Initierar sökvägar olika driftmiljöers konfigurationsfiler.

    .PARAMETER ConfigReferences
        Spec'ar en hashtable på formatet @{ Miljönamn = Path }
        Där miljönamn är ett hyffsat kort namn utan mellanslag, t.ex Produktion, Test, QA etc
        Path anger en full sökväg till xml-konfigurationen för miljön.
        xml-konfigurationen anger kunder, system etc.

    .PARAMETER Location
        Anger vart denna konfiguration, som pekar ut miljökonfigurationerna, skall sparas.

	.EXAMPLE
        Initialize-BIFSettings -ConfigReferences @{ Prod = "\\fileserver\share$\BIF\config\production\BIF_production.conf"; Test = "\\fileserver\share$\BIF\config\test\BIF_production.conf";}

	.NOTES

	.LINK
#>
Function Initialize-BIFSettings {
    [cmdletBinding(SupportsShouldProcess=$True, ConfirmImpact="High")]
    Param(
        [Parameter(Mandatory=$True)]
        [hashtable]$ConfigReferences

        ,[Parameter(Mandatory=$False)]
        [ValidateSet('Current-Location','Module-Location')]
        [string]$Location='Module-Location'

        #,[Parameter(Mandatory=$False)]
        #[System.IO.Path]$Path
    )
    
    # Generated with New-FortikaPSFunction

    BEGIN {
		# If -debug is set, change $DebugPreference so that output is a little less annoying.
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If ($PSBoundParameters['Debug']) {
			$DebugPreference = 'Continue'
		}


        $ConfigFilename = "OLL.BIF.Utils.conf"


        # check if directories exists
        # check if hashtable keys are without spaces
        # 


        Switch ($Location) {
            "Custom" { 
                $ConfigStoragePath = $Path 
            }
            "Current-Location" {
                #if($Path) {
                #    Throw "Parameter Path can't be used with Location Current-Location"
                #}
                $ConfigStoragePath = (Get-Location).Path
            }
            "Module-Location" {                
                #if($Path) {
                #    Throw "Parameter Path can't be used with Location Module-Location"
                #}
                $ConfigStoragePath = Split-Path $PSCmdlet.MyInvocation.PSScriptRoot -Parent
            }
        }

        if(-Not $ConfigStoragePath) {
            Throw "Weops! Could not get ahold of a storage path!"
        }

        # test access to configuration path
        foreach($confname in $ConfigReferences.Keys) {
            #$confname = $_
            $conf = $ConfigReferences[$confname]

            if($(Test-Path -Path $conf) ) {
                Write-Warning "Configuration file `"$conf`" already exists. Not goint to overwrite it!"
            } else {
                # https://stackoverflow.com/questions/9735449/how-to-verify-whether-the-share-has-write-access

                Try {
                    if (-not $(_Test-DirectoryWriteAccess -Path $(Split-Path -Path $conf -Parent) -ErrorAction stop)) { Throw "No access to $conf" }
                }
                Catch { 
                    # catch here because function _Test-DirectoryWriteAccess uses a validate script that throws an exception
                    Write-Warning "You don't seem to have write access to configuration file `"$conf`". Check that the file exist and you have access rights to it."
                }
            }
        }

        $Overwrite = $True

        $ConfigStoragePath = Join-Path -Path $ConfigStoragePath -ChildPath $ConfigFileName
        if($(Test-Path -Path $ConfigStoragePath)) {
            Write-Warning "$ConfigStoragePath already exists!"
            
            if(-Not $pscmdlet.ShouldProcess("$ConfigStoragePath","Overwrite")) {
                $OverWrite=$False
            }
        } 
        
        if($Overwrite) {
            $ConfigReferences | Export-Clixml -Path $ConfigStoragePath
        } else {
            Write-Verbose "Not writing $ConfigStoragePath"
        }



    }

    PROCESS {
    }

    END {
    }
}

<#
Initialize-BIFSettings -Location Module-Location `
                        -ConfigReferences @{  Test = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\test\BIF_test_customers_and_systems.conf';
                                              Prod = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\prod\BIF_prod_customers_and_systems.conf';
                                              QA   = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\qa\BIF_qa_customers_and_systems.conf';
                                            }
#>
#@{ Prod = "d:\temp\BIF_production.conf"; Test = "d:\temp\BIF_production.conf";}




