<#
    .SYNOPSIS

    .DESCRIPTION
        Derived from https://stackoverflow.com/questions/822907/how-do-i-use-powershell-to-validate-xml-files-against-an-xsd#28458621

    .EXAMPLE
        Test-Xml

    .NOTES

    .LINK

#>
Function Test-Xml() {
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(ValueFromPipeline=$True, Mandatory=$False)]
        [string]$Xml

        ,[Parameter(Mandatory=$False)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$Path

        ,[Parameter(Mandatory=$False)]
        [ValidateScript({Test-Path -Path $_})]
        [Alias('SchemaFilePath')]
        [string]$SchemaPath

        ,[Parameter(Mandatory=$False)]
        [string]$Schema

        ,[Parameter(Mandatory=$False)]
        $Namespace = $null
    )

    # Validate parameters.
    # In theory this could be done with parameter sets.
    if($XML -and $Path) {
        Throw "Parameter XML and Path can not be used together"
    }

    if($SchemaPath -and $Schema) {
        Throw "Parameter SchemaPath and Schema can not be used together"    
    }

    if( $(-not $XML) -and $(-not $Path) ) {
        Throw "Parameter XML or Path must be specified"
    }

    if( $(-not $SchemaPath) -and $(-not $Schema) ) {
        Throw "Parameter SchemaPath or Schema must be specified"
    }




    [string[]]$Script:XmlValidationErrorLog = @()
    [scriptblock] $ValidationEventHandler = {
        $Script:XmlValidationErrorLog += "Line: $($_.Exception.LineNumber) Offset: $($_.Exception.LinePosition) - $($_.Message)"
    }

    if($Path) {
        # use resolve-path to resolve any relative path.
        # loading from relative paths fails
        $Path = (Resolve-Path -Path $Path).Path
    }

    if($SchemaPath) {
        # use resolve-path to resolve any relative path.
        # loading from relative paths fails
        $SchemaPath = (Resolve-Path -Path $SchemaPath).Path
    }


    $readerSettings = New-Object -TypeName System.Xml.XmlReaderSettings
    $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
    $readerSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints -bor
            [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation -bor 
            [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
    $readerSettings.add_ValidationEventHandler($ValidationEventHandler)
    try 
    {
        # Add will throw an exception if schema is invalid
        if($SchemaPath) {
            $readerSettings.Schemas.Add($Namespace, $SchemaPath) | Out-Null
        } else {
            $readerSettings.Schemas.Add($Namespace, [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($Schema)) ) | Out-Null
        }

        if($Path) {
            $reader = [System.Xml.XmlReader]::Create($Path, $readerSettings)
        } else {
            $reader = [System.Xml.XmlReader]::Create( [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($XML)), $readerSettings)
        }
        
        while ($reader.Read()) { }
    }
    catch {
        # read throws an exception if file has wrong encoding.
        $Script:XmlValidationErrorLog += ($_.Exception.InnerException.Message.ToString())
    }    
    finally {
        #handler to ensure we always close the reader sicne it locks files
        if($reader) {
            # close if we have a reader object
            $reader.Close()
        }
    }

    if ($Script:XmlValidationErrorLog) {
        Write-Verbose $($Script:XmlValidationErrorLog -join "`n")
        return $False
    }
    else {
        return $True
    }
}