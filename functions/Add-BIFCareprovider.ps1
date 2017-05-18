<#
    .SYNOPSIS
        Lägger till en vårdgivare till en viss kund.

    .DESCRIPTION
        Lägger till en vårdgivare till en viss kund.

    .PARAMETER CustomerName
        Anger för vilken kund vårdgivaren skall läggas upp.

    .PARAMETER CareproviderName
        Anger namnet på vårdgivaren.

    .PARAMETER CareproviderHSAId
        Anger HSA-Id för vårdgivaren.

    .PARAMETER SystemHSAId
        Om denna parameter anges läggs vårdigvaren endast till för ett visst system.

    .PARAMETER Environment
        Anger för vilken miljö vårdgivaren skall läggas till.

    .EXAMPLE
        Add-BIFCareprovider -CustomerName "Region Örebro län" -CareproviderName "Region Örebro län" -CareproviderHSAId "SE2321000164-7381037590003" -Environment Test

    .NOTES

    .LINK

#>
Function Add-BIFCareprovider {
    [cmdletBinding(SupportsShouldProcess=$True
            ,ConfirmImpact='Medium')]
    Param(
        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$CustomerName,

        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$CareproviderName,

        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$CareproviderHSAId,

        [Parameter(Mandatory=$False
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$SystemHSAId,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Prod','Test','QA')]
        [string]$Environment
    )

    BEGIN {
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


        _Backup-ConfigFile -FileName $EnvConfigFile


        # Get-BIFCustomer kan inte användas här eftersom det blir olika "dokumentkontext" på returnerad
        # data från Get-BIFCustomer och xml-noder skapade här.
        # Det finns sätt runt detta
        # http://stackoverflow.com/questions/3019136/error-the-node-to-be-inserted-is-from-a-different-document-context
        #$CustomerConf = Get-BIFCustomer -CustomerName $CustomerName -Environment $Environment
        # Istället plockar vi ut $CustomerConf från den ConfigData som har importerats i den här funktionen
        $CustomerConf = $ConfigData.OLLBIF.Customers.Customer | ? { $_.name -eq $CustomerName }

        if(-Not $CustomerConf) {
            Throw "Customer `"$CustomerName`" does not exist!"
        }
    }

    PROCESS {
        # lagra $ConfirmPreference ifall det ställs om
        $oldconfpref = $ConfirmPreference


        # Om $SystemHSAId är definierat så måste vi kolla om systemet finns på kunden
        if($SystemHSAId) {
            $System = $CustomerConf.Systems.system | ? { $_.hsaid -eq $SystemHSAId }
            if(-Not $System) {
                Throw "A system with HSA-id $systemHSAId does not exist on customer $CustomerName "
            }
        }

        $carep = $ConfigData.OLLBIF.Customers.customer.careproviders.careprovider | ? { $_.name -eq $CareproviderName -or $_.hsaid -eq $CareproviderHSAId }
        if($carep) {
            if($PSCmdlet.ShouldContinue("Careprovider `"$CareproviderName`" already exists! `r`nOr another careprovider with HSA-id $CareproviderHSAid already exists! `r`nAdd anyway?","Add-BIFCareprovider")) {
            } else {
                Throw "Careprovider `"$CareproviderName`" already exists! Or another careprovider with HSA-id `"$CareproviderHSAid`" already exists!"
            }

        } 

        $Newcareprovider = $ConfigData.CreateElement("Careprovider")
        $Newcareprovider.SetAttribute("name",$CareproviderName)
        $Newcareprovider.SetAttribute("hsaid",$CareproviderHSAId)

        # Om $SystemHSAId är definierat så skall nya vårdgivaren läggas till ett specifikt system
        if($SystemHSAId) {
            $ApplyToNode = $System
        } else {
            $ApplyToNode = $CustomerConf
        }

            if($ApplyToNode.Careproviders) {
                try {
                    # out-null här eftersom AppendChild även returnerar datat som läggs till.
                    # Vi vill inte förorena pipelime med oavsiktlig output        
                    $ApplyToNode.Careproviders.AppendChild($Newcareprovider) | Out-Null
                }
                catch {
                    Throw "Could not add new careprovider to `"$CustomerName`". Check config xml. The Careproviders tag must not exist and be empty. Remove it in that case."
                }
            } else {
                $CareprovidersNode = $ConfigData.CreateElement("Careproviders")
                $CareprovidersNode.AppendChild($Newcareprovider) | Out-Null

                # out-null här eftersom AppendChild även returnerar datat som läggs till.
                # Vi vill inte förorena pipelime med oavsiktlig output        
                $ApplyToNode.AppendChild($CareprovidersNode) | Out-Null
            }
       


        $ConfirmPreference = $oldconfpref
    }

    END {
        if($EnvConfigFile) {
            $Configdata.save($EnvConfigFile)
        } else {
            Throw "Can't save configuration! Which file to save to is not set!"
        }
    }
}
