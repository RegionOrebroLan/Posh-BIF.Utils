# Check if $PSScriptRoot is set. If not set then we might be running "interactivly", so set the module root to current location.
if(-Not ${PSScriptRoot}) {
    $ModuleRoot = (Get-Location).Path
} else {
    $ModuleRoot = ${PSScriptRoot}
}


Write-host $($MyInvocation | out-string)

Write-host $($MyInvocation.Line.GetType() | out-string)


# !!
# Keys in this hashtable must be without spaces!
# They are used to create a dynamic parameter for tab completion in other functions.
# A key with name "test env" does not work!
$script:EnvironmentConfig = @{ Test = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\test\BIF_test_customers_and_systems.conf';
                               Prod = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\prod\BIF_prod_customers_and_systems.conf';
                               QA   = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\qa\BIF_qa_customers_and_systems.conf';
                             }


# TODO: warn if there's not settings!


# make sure helper functions are included first
. ${ModuleRoot}\functions\helpers\_OLL.BIF.Utils-dynamic-params_QuotedStringHelperClass.ps1
. ${ModuleRoot}\functions\helpers\_OLL.BIF.Utils-dynamic-params_Get-ObjectTypesForValidateSet.ps1
. ${ModuleRoot}\functions\helpers\_New-DynamicValidateSetParam.ps1
. ${ModuleRoot}\functions\helpers\_helper_functions.ps1


# dot-source cmdlet functions by listing all ps1-files in subfolder functions to where the module file is located
dir ${ModuleRoot}\functions\*.ps1 | Sort-Object Name | ? { $_.Name -notlike '_helper_functions*'} | ForEach-Object { . $_.FullName }
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
$str = Get-ChildItem function: | ? { $_.ModuleName -eq "OLL.BIF.Utils"  -and $_.Name -notlike '_*' } | Select Name | Out-String -Width 50


Write-Verbose "The following function are not available in the current session: $str" -Verbose:$true
Write-Verbose "For information about a specific function, see get-help <kommando>" -Verbose:$true


# test access to configuration files
$script:EnvironmentConfig.keys  | ForEach-Object {

    $confname = $_
    $conf = $script:EnvironmentConfig[$confname]

    if(-Not $(Test-Path -Path $conf) ) {
        Write-Warning "Could not find configuration file `"$conf`". Check that the file exist and you have access rights to it."
    } else {
        # http://stackoverflow.com/questions/22943289/powershell-what-is-the-best-way-to-check-whether-the-current-user-has-permissio
        try { 
            [io.file]::OpenWrite($conf).close()
        }
        Catch { 
            Write-Warning "You don't seem to have write access to configuration file `"$conf`". Check that the file exist and you have access rights to it."
        }    
    }
}
