# OBS!
# Keys (Test, prod, QA) i denna hashtable måste vara utan space!
# De används för att skapa dynamisk parameter tab completion i cmdlets.
# Att ange en miljö som "ett test" fungerar inte.
$script:EnvironmentConfig = @{ Test = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\test\BIF_test_customers_and_systems.conf';
                               Prod = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\prod\BIF_prod_customers_and_systems.conf';
                               QA   = 'S:\1Driftdokumentation\BIF\Säkerhetstjänster\Konfiguration\Accessregler\qa\BIF_qa_customers_and_systems.conf';
                        }


# dot-source functions

# make sure helper functions are included first
. ${PSScriptRoot}\functions\helpers\_OLL.BIF.Utils-dynamic-params_QuotedStringHelperClass.ps1
. ${PSScriptRoot}\functions\helpers\_New-DynamicValidateSetParam.ps1
. ${PSScriptRoot}\functions\helpers\_helper_functions.ps1


# dot-source cmdlet functions by listin all ps1-files in subfolder functions to where the module file is located
dir ${PSScriptRoot}\functions\*.ps1 | Sort-Object Name | ? { $_.Name -notlike '_helper_functions*'} | ForEach-Object { . $_.FullName }


# make cmdlets available by exporting them.
Get-ChildItem function: | ? { $_.Name -like '*BIF*' -and $_.Name -notlike '_*' } | Select Name | ForEach-Object { Export-ModuleMember -Function $_.Name }




#################################################################################
#
# Visa information om importerade funktioner samt testa åtkomst till konfigfiler
# Visa inte funktioner som börjar med "_". Dessa anses vara interna.
#
# Att behövs sätta width på Out-String för att få det se normalt ut är rätt hjärndött...
$str = Get-ChildItem function: | ? { $_.ModuleName -eq "OLL.BIF.Utils"  -and $_.Name -notlike '_*' } | Select Name | Out-String -Width 50

Write-Verbose "Följande funktioner för att hantera lokala säkerhetstjänster är nu tillgängliga i denna session: $str" -Verbose:$true
Write-Verbose "För info om respektive kommando se, get-help <kommando>" -Verbose:$true

# testa åtkomst till 
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

