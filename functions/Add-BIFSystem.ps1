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
        [string]$CustomerName

        ,[Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$SystemName

        ,[Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$SystemHSAId

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




        _Backup-ConfigFile -FileName $EnvConfigFile

        # Get-BIFCustomer can not be used here because the data will be from a different "document context" in relation to xml nodes
        # created here.
        # There seems to be a way around that.
        # http://stackoverflow.com/questions/3019136/error-the-node-to-be-inserted-is-from-a-different-document-context
        #$CustomerConf = Get-BIFCustomer -CustomerName $CustomerName -Environment $Environment
        #
        # instead $CustomerConf is pulled from the xml config that is imported in this function
        $CustomerConf = $ConfigData.OLLBIF.Customers.Customer | ? { $_.name -eq $CustomerName }

        if(-Not $CustomerConf) {
            Throw "Customer $Customer does not exists!"
        }

        #$sys = $ConfigData.OLLBIF.Customers.customer.systems.system | ? { $_.hsaid -eq $SystemHSAId -or $_.name -eq $SystemName }
        # Check that HSA id is unique. Systems can have the same name between customers, main thing used here is that HSA id is unique
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
                # out-null because AppendChild also returnes data and the pipeline should not be polluted.
                $CustomerConf.Systems.AppendChild($NewSystem) | Out-Null
            }
            catch {
                Throw "Could not add new system to $CustomerName. Check config xml. The Systems tag must not exist and be empty. Remove it in that case."
            }
        } else {
            $SystemsNode = $ConfigData.CreateElement("Systems")
            $SystemsNode.AppendChild($NewSystem) | Out-Null

            # out-null because AppendChild also returnes data and the pipeline should not be polluted.
            $CustomerConf.AppendChild($SystemsNode) | Out-Null
        }
    }

    END {
        if($EnvConfigFile) {
            $Configdata.save($EnvConfigFile)
        } else {
            Throw "Can't save configuration! Which file to save to is not set!"
        }
    }
}
