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
        [string]$CustomerName,

        [Parameter(Mandatory=$False)]
        [string]$SystemName,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Prod','Test','QA')]
        [string]$Environment
    )


    if(-Not $script:EnvironmentConfig) {
        Throw "Global Environment config is not set! Is the module properly loaded?"
    }
        
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


    # Skapa katalog där filerna kommer skrivas, samt backupkatalog
    $OutputDirectory = "$(split-path -path $script:EnvironmentConfig[$Environment])\SystemRules"
    _New-DirectoryWithTest -Name $OutputDirectory

    $BackupDirectory = "$OutputDirectory\Backup"
    _New-DirectoryWithTest -Name $BackupDirectory


    # Accessfiler för system består av en lista med vårdgivare som ett visst system har åtkomst till.
    # Detta är det xml-entry där varje system defineras med.
    # %CAREPROVIDERNAME% byts till namnet på vårdgivaren
    # %CAREPROVIDERHSAID% byts till hsa-id't på vårdgivaren
$SystemAccessEntryTemplate = @"
`t`t`t<saml:Attribute Name="urn:sambi:names:attribute:careProviderHsaId">
`t`t`t`t<!-- %CAREPROVIDERNAME% -->
`t`t`t`t<saml:AttributeValue>%CAREPROVIDERHSAID%</saml:AttributeValue>
`t`t`t</saml:Attribute>
"@


    # Om en specifik kund är angiven plocka ut den.
    if($CustomerName) {
        $CustomerSelection = Get-BIFCustomer -CustomerName $CustomerName -Environment $Environment
    } else {
        # om ingen kund är spec'ad, ta hela listan från conf.
        $CustomerSelection = $ConfigData.OLLBIF.Customers.Customer
    }


    # loopa kunder i aktuell selection
    foreach($Customer in $CustomerSelection) {

        If($SystemName) {
            $SystemSelection = $Customer.Systems.System | ? { $_.Name -eq $SystemName }
        } else {
            $SystemSelection = $Customer.Systems.System 
        }

        # loopa system i selection
        foreach($System in $SystemSelection) {   

            Write-Progress -Activity $Customer.name -CurrentOperation $System.name

            $SystemAccessData = Get-Content $ConfigData.OLLBIF.Environment.SystemAccessTemplate -encoding UTF8 -raw | _Expand-VariablesInString -VariableMappings @{ SYSTEMHSAID = $System.hsaid }

            $SystemData = ""
            # loopa alla vårdgivare
            foreach($Careprovider in $Customer.Careproviders.Careprovider) {
            
                # lägg till accessregel till $systemdata-strängen
                $SystemData += $SystemAccessEntryTemplate | _Expand-VariablesInString -VariableMappings @{ CAREPROVIDERNAME = $Careprovider.name; CAREPROVIDERHSAID = $Careprovider.hsaid }
                $SystemData += "`r`n"
            }

       
            # loopa alla eventuella vårdgivare specifikt för systemet
            foreach($Careprovider in $System.Careproviders.Careprovider) {
            
                # lägg till accessregel till $systemdata-strängen
                $SystemData += $SystemAccessEntryTemplate | _Expand-VariablesInString -VariableMappings @{ CAREPROVIDERNAME = $Careprovider.name; CAREPROVIDERHSAID = $Careprovider.hsaid }
                $SystemData += "`r`n"
            }
        

            # En replace görs av alla "farliga" tecken så att inte shortname innehåller något som kan traversera sökvägar.
            $OutputFileName = "$($OutputDirectory)\regler_$($Customer.shortname -replace "[/.\\:]","-")_vårdsystem_$($System.Name)_$($system.hsaid).xml"

            if( $(Test-Path $OutputFileName) ) {
                Write-Warning "$OutputFileName already exists. Backing up to $BackupDirectory"
                Move-Item $OutputFileName "$BackupDirectory\$(split-path -path $OutputFileName -Leaf)_$TS" -Verbose:$False
            }


            # skriv ut datat till fil.
            $SystemAccessData | _Expand-VariablesInString -VariableMappings @{ SYSTEMACCESSENTRIES = $Systemdata } | `
                    Out-File -FilePath $OutputFileName -Encoding utf8

            Write-Verbose "File written to $OutputFileName"
   
        }
    }
}
