<#
	.SYNOPSIS        

	.DESCRIPTION        

    .PARAMETER         

	.EXAMPLE        

	.NOTES

	.LINK

#>
Function Update-BIFModuleManifest {
    [cmdletBinding()]
    Param(
        
    )

    BEGIN {
		# If -debug is set, change $DebugPreference so that output is a little less annoying.
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If ($PSBoundParameters['Debug']) {
			$DebugPreference = 'Continue'
		}



        $ManifestParams = @{
            Path = ''

            # Script module or binary module file associated with this manifest.
            RootModule = 'OLL.BIF.Utils.psm1'

            # Version number of this module.
            # NuGet does not like just 1.0, seems to need 1.0.0
            # https://github.com/PowerShell/PowerShellGet/issues/88
            ModuleVersion = '1.0.0'

            # Supported PSEditions
            # CompatiblePSEditions = @()

            # ID used to uniquely identify this module
            GUID = '8cc6b310-5aaa-4b79-b66a-1282b4b1af34'

            # Author of this module
            Author = 'Andreas Östlund'

            # Company or vendor of this module
            CompanyName = 'Region Örebro län'

            # Copyright statement for this module
            Copyright = ' '

            # Description of the functionality provided by this module
            Description = 'Simple module for managing configuration of Lokala sakerhetstjanster'

            # Minimum version of the Windows PowerShell engine required by this module
            # PowerShellVersion = ''

            # Name of the Windows PowerShell host required by this module
            # PowerShellHostName = ''

            # Minimum version of the Windows PowerShell host required by this module
            # PowerShellHostVersion = ''

            # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
            # DotNetFrameworkVersion = ''

            # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
            # CLRVersion = ''

            # Processor architecture (None, X86, Amd64) required by this module
            # ProcessorArchitecture = ''

            # Modules that must be imported into the global environment prior to importing this module
            # RequiredModules = @()

            # Assemblies that must be loaded prior to importing this module
            # RequiredAssemblies = @()

            # Script files (.ps1) that are run in the caller's environment prior to importing this module.
            ScriptsToProcess = @()

            # Type files (.ps1xml) to be loaded when importing this module
            # TypesToProcess = @()

            # Format files (.ps1xml) to be loaded when importing this module
            # FormatsToProcess = @()

            # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
            # NestedModules = @()

            # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
            FunctionsToExport = @()

            # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
            CmdletsToExport = @()

            # Variables to export from this module
            VariablesToExport = '*'

            # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
            AliasesToExport = @()

            # DSC resources to export from this module
            # DscResourcesToExport = @()

            # List of all modules packaged with this module
            # ModuleList = @()

            # List of all files packaged with this module
            # FileList = @()

            # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
            PrivateData = @{
            } # End of PrivateData hashtable

            # HelpInfo URI of this module
            # HelpInfoURI = ''

            # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
            # DefaultCommandPrefix = ''
        }


        # We assume that this function is located in a subdirectory to the module

        if(-Not ${PSScriptRoot}) {
            $ModuleRoot = Split-path -path (Get-Location).Path -Parent
        } else {
            $ModuleRoot = Split-Path -path ${PSScriptRoot} -Parent
        }

        # Do some sanity testing
        $FunctionsDir = get-item -Path (join-path -Path $ModuleRoot -ChildPath "functions")
        if( (-Not $FunctionsDir) -or (-Not $FunctionsDir.PSIsContainer) ) {
            Throw "Weops! Our assumed module directory $ModuleRoot does not seem to be correct!"
        }


        $ManifestParams.Path = $(Join-Path -Path $ModuleRoot -ChildPath "OLL.BIF.Utils.psd1" )

        # There is probably a better way to do this...
        $Functions = get-childitem "${ModuleRoot}\functions\*.ps1" | ? { $_.Name -like '*-BIF*.ps1'} | ForEach-Object { $_.Name.Replace(".ps1","") }

        $ManifestParams.FunctionsToExport = $Functions

        New-ModuleManifest @ManifestParams

        # work-around for git treating UTF-16 as binary
        #$ManifestContent = Get-Content -Path $ManifestParams.Path
        #$ManifestContent | Set-Content -Path $ManifestParams.Path -Encoding UTF8
    }

    PROCESS {
    }

    END {
    }
}



Update-BIFModuleManifest

