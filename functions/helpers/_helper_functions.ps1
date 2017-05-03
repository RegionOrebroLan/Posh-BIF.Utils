
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

        $BackupDir = "$(split-path $FileName)\config_backup"
        $BackupFile = "$(split-path $FileName -Leaf)_$TS"

        Write-Verbose "Backing up config file to $Backupdir"

        _New-DirectoryWithTest $BackupDir

        copy-item $FileName "$BackupDir\$BackupFile" -Verbose:$false        
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
                mkdir $Name -ErrorAction stop | Out-Null
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

