<#
    .SYNOPSIS
        Lägger till en kund till en viss miljö.

    .DESCRIPTION
        Lägger till en kund till en viss miljö.

    .PARAMETER CustomerName
        Anger namnet på kunden som skall läggas till.

    .PARAMETER Shortname
        Anger ett "kortnamn" på kunden. Detta namn skall vara unikt och utan mellanslag. T.ex den gänse förkortningen på organisationen.

    .PARAMETER Environment
        Anger för vilken miljö kunden skall läggas till.

    .EXAMPLE
        Add-BIFCustomer -CustomerName "Region Örebro län" 

    .NOTES

    .LINK

#>
Function Add-BIFCustomer {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$CustomerName

        ,[Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$Shortname

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

        $customer = $ConfigData.OLLBIF.Customers.Customer | ? { $_.name -eq $CustomerName -or $_.shortname -eq $Shortname }

        if($customer) {
            Throw "Customer $CustomerName already exists, or shortname $Shortname already defined"
        }

    }

    PROCESS {
        $NewCustomer = $ConfigData.CreateElement("Customer")
        $NewCustomer.SetAttribute("name",$CustomerName)
        $NewCustomer.SetAttribute("shortname",$Shortname)

        # using out-null here because AppendChild resturned the data that is added.
        # We don't want to pollute the pipe 
        $Configdata.OLLBIF.Customers.AppendChild($NewCustomer) | Out-Null

    }

    END {
        if($EnvConfigFile) {
            $Configdata.save($EnvConfigFile)
        } else {
            Throw "Can't save configuration! Which file to save to is not set!"
        }
    }
}
