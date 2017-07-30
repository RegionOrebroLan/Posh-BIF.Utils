# Check if $PSScriptRoot is set. If not set then we might be running "interactivly", so set the module root to current location.
if(-Not ${PSScriptRoot}) {
    $ModuleRoot = (Get-Location).Path
} else {
    $ModuleRoot = ${PSScriptRoot}
}

# TODO: warn if there's not settings!


# make sure helper functions are included first
. ${ModuleRoot}\functions\helpers\_OLL.BIF.Utils-dynamic-params_QuotedStringHelperClass.ps1
. ${ModuleRoot}\functions\helpers\_OLL.BIF.Utils-dynamic-params_Get-ObjectTypesForValidateSet.ps1
. ${ModuleRoot}\functions\helpers\_New-DynamicValidateSetParam.ps1
. ${ModuleRoot}\functions\helpers\_helper_functions.ps1


# dot-source cmdlet functions by listing all ps1-files in subfolder functions to where the module file is located
$FunctionPath = Join-Path -Path ${ModuleRoot} -ChildPath "functions"
Get-ChildItem -Path $FunctionPath -Filter "*.ps1" | ? { $_.Name -like '*-BIF*.ps1'} | Sort-Object | ForEach-Object { . $_.FullName }
#dir ${ModuleRoot}\functions\*.ps1 | Sort-Object Name | ? { $_.Name -notlike '_helper_functions*'} | ForEach-Object { . $_.FullName }
#write-host $(dir ${ModuleRoot}\functions\*.ps1 | Sort-Object Name | out-string)


# make cmdlets available by exporting them.
# This has been moved to the module manifest.
#Get-ChildItem function: | ? { $_.Name -like '*BIF*' -and $_.Name -notlike '_*' } | Select Name | ForEach-Object { Export-ModuleMember -Function $_.Name }



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
