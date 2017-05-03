<#
    .SYNOPSIS
        Lägger till ett system till en viss kund.

    .DESCRIPTION
        Lägger till ett system till en viss kund.

    .PARAMETER CustomerName
        Anger för vilken kund systemet skall läggas till.

    .PARAMETER SystemName
        Anger namnet på systemet.

    .PARAMETER SystemHSAId
        Anger HSA-Id't på systemet.
        Detta är HSA-Id på det certifikat som systemet använder för att autentisera sig mot lokala säkerhetstjänster.

    .PARAMETER Environment
        Anger för vilken miljö systemet skall läggas till.

    .EXAMPLE
        Add-BIFSystem -CustomerName "Region Örebro län" -SystemName "Kibi" -SystemHSAId "SE162321000164-0175" -Environment Prod

    .NOTES

    .LINK

#>
Function Add-BIFSystem {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$CustomerName,
        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$SystemName,
        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$SystemHSAId,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Prod','Test','QA')]
        [string]$Environment
    )

    BEGIN {
        try {
            [xml]$ConfigData = Get-Content $script:EnvironmentConfig[$Environment] -ErrorAction Stop
        }
        catch {
            Throw "Could not load configuration from `"$($script:EnvironmentConfig[$Environment])`". Make sure the file exists and your account has access to it."
        }

        _Backup-ConfigFile -FileName $script:EnvironmentConfig[$Environment]

        # Get-BIFCustomer kan inte användas här eftersom det blir olika "dokumentkontext" på returnerad
        # data från Get-BIFCustomer och xml-noder skapade här.
        # Det finns sätt runt detta
        # http://stackoverflow.com/questions/3019136/error-the-node-to-be-inserted-is-from-a-different-document-context
        #$CustomerConf = Get-BIFCustomer -CustomerName $CustomerName -Environment $Environment
        # Istället plockar vi ut $CustomerConf från den ConfigData som har importerats i den här funktionen
        $CustomerConf = $ConfigData.OLLBIF.Customers.Customer | ? { $_.name -eq $CustomerName }

        if(-Not $CustomerConf) {
            Throw "Customer $Customer does not exists!"
        }

        #$sys = $ConfigData.OLLBIF.Customers.customer.systems.system | ? { $_.hsaid -eq $SystemHSAId -or $_.name -eq $SystemName }
        # Kolla endast HSA-id. System kan heta samma sakner mellan olika kunder, huvudsaken att HSA-id är unikt.
        $sys = $ConfigData.OLLBIF.Customers.customer.systems.system | ? { $_.hsaid -eq $SystemHSAId }
        if($sys) {
            Throw "Another system with HSA-id $SystemHSAId already exists!"
        }
    }

    PROCESS {
        $NewSystem = $ConfigData.CreateElement("System")
        $NewSystem.SetAttribute("name",$SystemName)
        $NewSystem.SetAttribute("hsaid",$SystemHSAId)

        if($CustomerConf.Systems) {
            try {
                # out-null här eftersom AppendChild även returnerar datat som läggs till.
                # Vi vill inte förorena pipelime med oavsiktlig output        
                $CustomerConf.Systems.AppendChild($NewSystem) | Out-Null
            }
            catch {
                Throw "Could not add new system to $CustomerName. Check config xml. The Systems tag must not exist and be empty. Remove it in that case."
            }
        } else {
            $SystemsNode = $ConfigData.CreateElement("Systems")
            $SystemsNode.AppendChild($NewSystem) | Out-Null

            # out-null här eftersom AppendChild även returnerar datat som läggs till.
            # Vi vill inte förorena pipelime med oavsiktlig output        
            $CustomerConf.AppendChild($SystemsNode) | Out-Null
        }
    }

    END {
        $Configdata.save($script:EnvironmentConfig[$Environment])
    }
}
