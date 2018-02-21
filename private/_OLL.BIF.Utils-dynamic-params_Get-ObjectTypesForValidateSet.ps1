<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER xxxx

    .EXAMPLE

    .NOTES

    .LINK

#>
Function _OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames {
    [CmdletBinding()]
    Param(
    )
    BEGIN {
    }

    PROCESS {
        # Vi skapar en array av object av typen [DynParamQuotedString]
        # Detta för att hantera strängar som kan innehålla space.
        # Den sträng som sedan väljs kommer plockas upp via property'n OriginalString från objektet.
        $QuotedStringObjects = ${script:EnvironmentConfig}.Keys | ForEach-Object { [DynParamQuotedString] $_.ToString() }
		
        return $QuotedStringObjects
    }

    END {
    }
}


function _Test_OLL.BIF.Utils-dynamic-params_Get-ObjectTypesForValidateSet {

    _OLL.BIF.Utils-dynamic-params_Get-EnvironmentShortNames

}
