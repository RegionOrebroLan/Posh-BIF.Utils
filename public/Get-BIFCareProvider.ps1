<#
    .SYNOPSIS
        Listar alla vårdgivare för en viss miljö.

    .DESCRIPTION
        Listar alla vårdgivare för en viss miljö.

    .PARAMETER Environment
        Miljön som vårdgivare skall listas för

    .PARAMETER CustomerName
        Om parameter CustomerName anges så listas vårdgivare specifikt för en kund.

    .EXAMPLE
        Get-BIFCareprovider -Environment Prod

    .NOTES

    .LINK

#>
Function Get-BIFCareprovider {
    [cmdletBinding()]
    Param(
      [Parameter(Mandatory=$False)]
      [string]$CareProividerName

      ,[Parameter(Mandatory=$False)]
      [string]$CustomerName
    )
    DynamicParam {
        $RuntimeParameterDictionary = _New-DynamicValidateSetParam -ParameterName "Environment" `
                                                                   -ParameterType [DynParamQuotedString] `
                                                                   -Mandatory $True `
                                                                   -FillValuesWith "_OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames"
        return $RuntimeParameterDictionary
    }

    # Generated with New-FortikaPSFunction -name Get-BIFCareprovider -Params @{Environment=@{Type="string"; Parameter=@{Mandatory=$True}}; CustomerName="string"; CareProividerName="string"} -Path ./Posh-BIF.Utils/functions/Get-BIFCareProvider.ps1

    BEGIN {
        # If -debug is set, change $DebugPreference so that output is a little less annoying.
        #    http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

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
    }

    PROCESS {
      if( $(-Not $CustomerName) -and $(-Not $CareProviderName) ) {

        $ConfigData.OLLBIF.Customers.Customer  | ForEach-Object {
            $customer=$_
            $customer.CareProviders.CareProvider | ForEach-Object {
              $PropertyHash = [ordered]@{
                CareProviderName=$_.Name
                CareProviderHSAId=$_.hsaid
                CustomerName=$Customer.Name
                CustomerShortName=$Customer.ShortName
              }
              New-Object -TypeName psobject -Property $PropertyHash
            }
          }
      }

    }

    END {

    }
}
