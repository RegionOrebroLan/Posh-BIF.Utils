<#
    .SYNOPSIS
        Tar bort en kund för en viss miljö.

    .DESCRIPTION
    Tar bort en kund för en viss miljö.

    .PARAMETER CustomerName
        Anger namnet på kunden som skall plockas bort.

    .PARAMETER Shortname

    .PARAMETER Environment
        Anger för vilken miljö kunden skall tas bort från.

    .EXAMPLE
        Remove-BIFCustomer -CustomerName "Region Örebro län"

    .EXAMPLE
        Remove-BIFCustomer -ShortName "OLL"

    .NOTES

    .LINK
#>
Function Remove-BIFCustomer {
    [cmdletBinding(DefaultParameterSetName='LongName'
                  ,SupportsShouldProcess=$True)]
    Param(
        [Parameter(Mandatory=$True
                  ,ParameterSetName='LongName'
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$CustomerName

        ,[Parameter(Mandatory=$True
                  ,ParameterSetName='ShortName'
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$Shortname
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

        $customer = $ConfigData.OLLBIF.Customers.Customer | ? { $_.name -eq $CustomerName -or $_.shortname -eq $Shortname }

        $CustName = $CustomerName
        if(-Not $CustomerName) { $CustName = $Shortname }

        if(-Not $CustName) {
            Throw "Customer {0} could not be found" -f $CustName
        }
    }

    PROCESS {


        #TODO: Fixa radering
        <#
        $NewCustomer = $ConfigData.CreateElement("Customer")
        $NewCustomer.SetAttribute("name",$CustomerName)
        $NewCustomer.SetAttribute("shortname",$Shortname)

        # using out-null here because AppendChild resturned the data that is added.
        # We don't want to pollute the pipe
        $Configdata.OLLBIF.Customers.AppendChild($NewCustomer) | Out-Null
        #>
    }

    END {
      if($DataModified) {
          if($EnvConfigFile) {

            if($PSCmdlet.ShouldProcess($CustName,"Remove")) {
              $Configdata.save($EnvConfigFile)
            }
          } else {
              Throw "Can't save configuration! Which file to save to is not set!"
          }
      }
    }
}
