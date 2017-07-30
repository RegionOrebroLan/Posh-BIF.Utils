<#
    .SYNOPSIS
        Tar bort till en vårdgivare för en viss kund.

    .DESCRIPTION
    Tar bort till en vårdgivare för en viss kund.

    .PARAMETER CustomerName
        Anger för vilken kund vårdgivaren skall tas bort.

    .PARAMETER CareproviderName
        Anger namnet på vårdgivaren.

    .PARAMETER CareproviderHSAId
        Anger HSA-Id för vårdgivaren.

    .PARAMETER Environment
        Anger för vilken miljö vårdgivaren skall läggas till.

    .EXAMPLE

    .NOTES

    .LINK

#>
Function RemoveBIFCareprovider {
    [cmdletBinding(SupportsShouldProcess=$True
                  ,ConfirmImpact='Medium'
                  ,DefaultParameterSetName='ByCareProviderHSAId')]
    Param(
        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$CustomerName

        ,[Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
                  ,ParameterSetName='ByCareProviderName'
        )]
        [string]$CareproviderName

        ,[Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
                  ,ParameterSetName='ByCareProviderHSAId'
        )]
        [string]$CareproviderHSAId
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
            # use resolve-path to get the full path of file.
            # on .NET core there seems to be problem with saving to a relative path
            $EnvConfigFile = (Resolve-Path -Path $EnvConfigFile).Path

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
            Throw "Customer `"$CustomerName`" does not exist!"
        }
    }

    PROCESS {
        # store $ConfirmPreference in case it's changed
        $oldconfpref = $ConfirmPreference


        $carep = $ConfigData.OLLBIF.Customers.customer.careproviders.careprovider | ? { $_.name -eq $CareproviderName -or $_.hsaid -eq $CareproviderHSAId }
        if($carep) {
          #TODO: Add code...
        }



        $ConfirmPreference = $oldconfpref
    }

    END {
        if($EnvConfigFile) {
            #TODO: confirmation...
            #$Configdata.save($EnvConfigFile)
        } else {
            Throw "Can't save configuration! Which file to save to is not set!"
        }
    }
}
