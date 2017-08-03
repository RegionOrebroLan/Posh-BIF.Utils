<#
    .SYNOPSIS
        Lägger till en miljö.

    .DESCRIPTION

    .PARAMETER Name
      Anger namn på miljön.

    .PARAMETER SystemAccessTemplate
      Anger sökväg till mall för systemregler.

    .PARAMETER UserAccessTemplate
      Anger sökväg till mall för användarregler.

    .PARAMETER ConfigFile
      Anger sökväg till konfigurationsfil.
      Om filen som pekas ut redan finns skrivs inte aktuell konfig data dit, utan filen börjar direkt användas.

    .PARAMETER Version
      Anger version på miljön.

    .EXAMPLE
        Add-BIFEnvironment -Name Test -Version "2.5"

    .NOTES

    .LINK

#>
Function Add-BIFEnvironment {
    [cmdletBinding(SupportsShouldProcess=$True
                  ,ConfirmImpact='High')]
    Param(
      [Parameter(Mandatory=$False)]
      [string]$SystemAccessTemplate

      ,[Parameter(Mandatory=$False)]
      [string]$UserAccessTemplate

      ,[Parameter(Mandatory=$False)]
      [String]$ConfigFile

      ,[Parameter(Mandatory=$False)]
      [string]$Version

      ,[Parameter(Mandatory=$False)]
      [ValidateNoteNullOrEmpty()]
      [string]$Name
    )

    BEGIN {
        # If -debug is set, change $DebugPreference so that output is a little less annoying.
        #    http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
    }

    PROCESS {
    }

    END {
    }
}
