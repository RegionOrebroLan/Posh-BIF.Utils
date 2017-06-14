<#
	.SYNOPSIS        

	.DESCRIPTION        

    .PARAMETER         

	.EXAMPLE        

	.NOTES

	.LINK

#>
Function Initialize-BIFSettings {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [hashtable]$ConfigReferences

        ,[Parameter(Mandatory=$True)]
        [ValidateSet('Profile','Current-Location','Module-Location')]
        [string]$Location
    )

    BEGIN {
		# If -debug is set, change $DebugPreference so that output is a little less annoying.
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If ($PSBoundParameters['Debug']) {
			$DebugPreference = 'Continue'
		}


        # check if directories exists
        # check if hashtable keys are without spaces
        # 

    }

    PROCESS {
    }

    END {
    }
}
