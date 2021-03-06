﻿
Function _Backup-ConfigFile {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$FileName
    )

    BEGIN {
    }

    PROCESS {
        $TS = (Get-date).ToSTring('yyyyMMdd-HHmmss')

        #$BackupDir = "$(split-path $FileName)\config_backup"
        $BackupDir = Join-Path -Path $(Split-Path -Path $FileName) -ChildPath "config_backup"
        $BackupFile = "$(split-path $FileName -Leaf)_$TS"
        $BackupPath = Join-Path -Path $BackupDir -ChildPath $BackupFile

        Write-Verbose "Backing up config file to $BackupPath"

        _New-DirectoryWithTest $BackupDir

        copy-item -Path $FileName -Destination $BackupPath -Verbose:$false
    }

    END {
    }
}



Function _New-DirectoryWithTest {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True
                  ,ValueFromPipelineByPropertyName=$True
        )]
        [string]$Name
    )

    BEGIN {
    }

    PROCESS {
        if(-Not $(Test-Path $Name)) {
            try {
                # ErrorAction Stop för att try-catch skall funka

                Write-Debug "Creating $Name"

                # be very explicit with parameters to support other OS'es than windows
                new-item -Path $Name -type Directory -ErrorAction stop | Out-Null
            }
            catch {
                Throw $_
            }
        }
    }

    END {
    }
}


Function _Expand-VariablesInString {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True
                  ,ValueFromPipeline=$True)]
        [string]$Inputstring,

        [Parameter(Mandatory=$True)]
        [hashtable]$VariableMappings
    )


    foreach($key in $Variablemappings.Keys) {

        $InputString = $Inputstring.Replace("%"+$key+"%",$VariableMappings[$key])
    }


    return $Inputstring
}

<#
	.SYNOPSIS

	.DESCRIPTION

	.EXAMPLE

	.NOTES

	.LINK

#>
# https://stackoverflow.com/questions/9735449/how-to-verify-whether-the-share-has-write-access
Function _Test-DirectoryWriteAccess {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateScript({[IO.Directory]::Exists($_.FullName)})]
		[IO.DirectoryInfo]$Path

    )

	# If -debug is set, change $DebugPreference so that output is a little less annoying.
	#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
	If ($PSBoundParameters['Debug']) {
		$DebugPreference = 'Continue'
	}


  try {
        $testPath = Join-Path $Path ([IO.Path]::GetRandomFileName())
        Write-Debug "testpath: $testPath"
        [IO.File]::Create($testPath, 1, 'DeleteOnClose') | Out-Null

        return $true

    } catch {
        return $false
    } finally {
        Remove-Item $testPath -ErrorAction SilentlyContinue
    }
}
