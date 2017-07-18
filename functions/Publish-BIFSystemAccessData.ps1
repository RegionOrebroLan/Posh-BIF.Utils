<#
    .SYNOPSIS
        Skapar konfiguration för systemaccess.

    .DESCRIPTION
        Skapar konfiguration för systemaccess.

    .PARAMETER CustomerName
        Anger för vilken kund konfiguration skall skapas för.
        Om inte denna parameter anges kommer konfiguration för alla kunder att skapas.

    .PARAMETER SystemName
        Anger för vilket system konfigurationen skall skapas för.
        Om inte denna parameter anges kommer konfiguration för alla system att skapas.

    .PARAMETER Environment
        Anger den driftmiljö som konfigurationen skall skapas för.

    .EXAMPLE
        Publish-BIFSystemAccessData -Environment Prod

        Skapar om alla regler för systemaccess för alla system och kunder i driftmiljön Prod.

    .EXAMPLE
        Publish-BIFSystemAccessData -CustomerName "Region Örebro län" -Environment Test

        Skapar om alla regler för systemaccess för alla system till kunden "Region Örebro län" i driftmiljön Test.

    .NOTES

    .LINK

#>
Function Publish-BIFSystemAccessData {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
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


        # Parameter sanity checks
        if(-Not $CustomerName -and  $SystemName) {
            Throw "If SystemName is specified CustomerName must also be specified."
        }    

        if($CustomerName -and -Not $(Test-BIFCustomer -CustomerName $CustomerName -Environment $Environment) ) {
            Throw "Customer $CustomerName does not exists"
        }

        if($SystemName -and -Not $(Test-BIFSystem -CustomerName $CustomerName -SystemName $SystemName -Environment $Environment) ) {
            Throw "System $SystemName is not defined for customer $CustomerName"
        }


        $TS = (Get-date).ToSTring('yyyyMMdd-HHmmss')

        # create a directory to store the files, and a backup directory
        $OutputDirectory = "$(split-path -path $script:EnvironmentConfig[$Environment])\SystemRules"
        _New-DirectoryWithTest -Name $OutputDirectory

        $BackupDirectory = "$OutputDirectory\Backup"
        _New-DirectoryWithTest -Name $BackupDirectory


        # Access files for systems consists of a list with care providers that a specific system has access to.
        # This is the xml entry that each system is defined by.
        # %CAREPROVIDERNAME% byts is replaced with the name of the care provider.
        # %CAREPROVIDERHSAID% is replaced with the HSA id of the care giver.
        $SystemAccessEntryTemplate = @"
`t`t`t<saml:Attribute Name="urn:sambi:names:attribute:careProviderHsaId">
`t`t`t`t<!-- %CAREPROVIDERNAME% -->
`t`t`t`t<saml:AttributeValue>%CAREPROVIDERHSAID%</saml:AttributeValue>
`t`t`t</saml:Attribute>
"@


        # if a specific customer is supplied, then get that.
        if($CustomerName) {
            $CustomerSelection = Get-BIFCustomer -CustomerName $CustomerName -Environment $Environment
        } else {
            # if no customer is specified, get all the customer from the config
            $CustomerSelection = $ConfigData.OLLBIF.Customers.Customer
        }


        # loop all customer in current selection
        foreach($Customer in $CustomerSelection) {

            If($SystemName) {
                $SystemSelection = $Customer.Systems.System | ? { $_.Name -eq $SystemName }
            } else {
                $SystemSelection = $Customer.Systems.System 
            }

            # loop all systems in selection
            foreach($System in $SystemSelection) {   

                Write-Progress -Activity $Customer.name -CurrentOperation $System.name

                $SystemAccessData = Get-Content $ConfigData.OLLBIF.Environment.SystemAccessTemplate -encoding UTF8 -raw | _Expand-VariablesInString -VariableMappings @{ SYSTEMHSAID = $System.hsaid }

                $SystemData = ""

                # loop all care givers
                foreach($Careprovider in $Customer.Careproviders.Careprovider) {
            
                    # add an access rule to the $systemdata string
                    $SystemData += $SystemAccessEntryTemplate | _Expand-VariablesInString -VariableMappings @{ CAREPROVIDERNAME = $Careprovider.name; CAREPROVIDERHSAID = $Careprovider.hsaid }
                    $SystemData += "`r`n"
                }

       
                # If there's any care givers specific for the current system, then loop those
                foreach($Careprovider in $System.Careproviders.Careprovider) {

                    # add an access rule to $systemdata
                    $SystemData += $SystemAccessEntryTemplate | _Expand-VariablesInString -VariableMappings @{ CAREPROVIDERNAME = $Careprovider.name; CAREPROVIDERHSAID = $Careprovider.hsaid }
                    $SystemData += "`r`n"
                }
        

                # A replace is made of all "dangerous" characters so that the shortname can't traverse paths
                $OutputFileName = "$($OutputDirectory)\regler_$($Customer.shortname -replace "[/.\\:]","-")_vårdsystem_$($System.Name)_$($system.hsaid).xml"

                if( $(Test-Path $OutputFileName) ) {
                    Write-Warning "$OutputFileName already exists. Backing up to $BackupDirectory"
                    Move-Item $OutputFileName "$BackupDirectory\$(split-path -path $OutputFileName -Leaf)_$TS" -Verbose:$False
                }


                # Write the data to a file
                $SystemAccessData | _Expand-VariablesInString -VariableMappings @{ SYSTEMACCESSENTRIES = $Systemdata } | `
                        Out-File -FilePath $OutputFileName -Encoding utf8

                Write-Verbose "File written to $OutputFileName"
   
            }
        }
    }

    PROCESS {
    }

    END {
    }
}