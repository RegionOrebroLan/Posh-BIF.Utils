# Check if $PSScriptRoot is set. If not set then we might be running "interactivly", so set the module root to current location.
if(-Not ${PSScriptRoot}) {
    $ModuleRoot = (Get-Location).Path
} else {
    $ModuleRoot = ${PSScriptRoot}
}

# TODO: warn if there's not settings!


# make sure helper functions are included first
Get-ChildItem -Path $(Join-Path -Path $ModuleRoot -ChildPath "private") | ForEach-Object { . $_.FullName }




# dot-source cmdlet functions by listing all ps1-files in subfolder public to where the module file is located
$PublicFunctionPath = Join-Path -Path ${ModuleRoot} -ChildPath "public"
Get-ChildItem -Path $PublicFunctionPath -Filter "*.ps1" | ? { $_.Name -like '*-BIF*.ps1'} | Sort-Object | ForEach-Object { . $_.FullName }




#################################################################################
#
# Write a message about imported functions
# Don't show functions starting with "_". These are considered internal.
#
# Should it really be neccessary to set width on Out-String to make it look good on terminal?
$str = Get-ChildItem function: | ? { $_.ModuleName -eq "Posh-BIF.Utils"  -and $_.Name -notlike '_*' } | Select Name | Out-String -Width 50


Write-Verbose "The following functions are now available in the current session: $str" -Verbose:$true
Write-Verbose "For information about a specific function, see get-help <command>" -Verbose:$true

# Read config
#Use-BIFSettings -Debug -verbose
Use-BIFSettings
