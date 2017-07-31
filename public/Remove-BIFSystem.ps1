<#
    .SYNOPSIS
        Raderar ett system för en viss kund.

    .DESCRIPTION
        Raderar ett system för en viss kund.

    .PARAMETER CustomerName
        Anger för vilken kund systemet tillhör..

    .PARAMETER SystemName
        Anger namnet på systemet.

    .PARAMETER Environment
        Anger för vilken miljö systemet skall raderas från.

    .EXAMPLE
        Remove-BIFSystem -CustomerName "Region Örebro län" -SystemName "Kibi" -Environment Prod

    .NOTES

    .LINK
#>
Function Remove-BIFSystem {
    [cmdletBinding(ConfirmImpact="High",
                SupportsShouldProcess=$True)]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$CustomerName

        ,[Parameter(Mandatory=$False)]
        [string]$SystemName

        <#
        ,[Parameter(Mandatory=$True)]
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
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If ($PSBoundParameters['Debug']) {
			$DebugPreference = 'Continue'
		}

        # Load parameter for Environment from dynamic param
        $Environment = $PSBoundParameters["Environment"].OriginalString


        if(-Not $script:EnvironmentConfig) {
            Throw "Global Environment config is not set! Is the module properly loaded?"
        }

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


        _Backup-ConfigFile -FileName $EnvConfigFile

        # Flag to indicate if we should save
        $DataModified = $False

    }

    PROCESS {

        $System = Get-BIFSystem -CustomerName $CustomerName -SystemName $SystemName -Environment $Environment

        if(-not $System) {
            Throw "System $SystemName not found for customer $CustomerName in environment $Environment"
        }


        # TODO: add support for -confirm / -force

        # TODO: Check if possible to select nodes case insensitive
        #       Now the XPath selection is case sensitive

        # find the parent node
        $ParentNode = $ConfigData.SelectSingleNode("/OLLBIF/Customers/Customer[@name='$($CustomerName)']/Systems")
        if(-not $ParentNode) {
            Throw "Weops! Could not find the Systems xml-node for customer $CustomerName`r`nCheck that the config file is valid and that names are specified case SENSITIVE!"
        }

        $node = $ConfigData.SelectSingleNode("/OLLBIF/Customers/Customer[@name='$($CustomerName)']/Systems/System[@name='$($SystemName)' and @hsaid='$($System.hsaid)']")
        if(-not $node) {
            Throw "Weops! Could not find the xml-node system $SystemName in the xml-file`r`nCheck that the config file is valid and that names are specified case SENSITIVE!"
        }

        if($PSCmdlet.ShouldProcess("$SystemName","Remove")) {
            $ParentNode.RemoveChild($node) | Out-Null
            $DataModified = $True
        }
    }

    END {
        if($DataModified) {
            if($EnvConfigFile) {

                #TODO: confirmation

                #Apparently xmldocument.Save(string filename) is not available on .NET core (OSX)
                if($PSEdition -eq "Core") {
                  # we use a streamWriter instead.
                  # this approach is probably available on full .NET as well
                  $Configdata.Save([System.IO.StreamWriter]::new($EnvConfigFile))
                } else {
                  $Configdata.save($EnvConfigFile)
                }

                Write-Warning "Any generated configuration files for `"$SystemName`" must be removed manually!"

            } else {
                Throw "Can't save configuration! Which file to save to is not set!"
            }
        }
    }
}
