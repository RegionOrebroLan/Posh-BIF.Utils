<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER xxxx

    .EXAMPLE

    .NOTES

    .LINK

#>
Function _New-DynamicValidateSetParam {
    [CmdletBinding()]
    Param(
        [Parameter (Mandatory=$True,
                    HelpMessage='The name of the parameter')]
        [string]$ParameterName,

        [Parameter (Mandatory=$True,
                    HelpMessage='The parameter type [string], [int] etc')]
        [System.Object]$ParameterType,

        [Parameter (Mandatory=$True,
                    HelpMessage='Help')]
        [boolean]$Mandatory,

        [Parameter (Mandatory=$False,
                    HelpMessage='Help')]
        [int]$ParameterPosition,

        [Parameter (Mandatory=$False,
                    HelpMessage='Hashtable med ytterligare parameter-properties. Från klassen System.Management.Automation.ParameterAttribute')]
        [hashtable]$ExtraParameterProperties,

        [Parameter (Mandatory=$True,
                    HelpMessage='Powershell commands that returns a string which fills the values. This is run through Invoke-Expression')]
        [string]$FillValuesWith,

        [Parameter (Mandatory=$False,
                    HelpMessage='An existing parameter dictionary object. If defined this object is used to add the parameter. If not specified a new System.Management.Automation.RuntimeDefinedParameterDictionary object is created and returned.')]
        [System.Management.Automation.RuntimeDefinedParameterDictionary]$RuntimeParameterDictionary
    )

    BEGIN {

        if(-Not $RuntimeParameterDictionary) {
            # Create the dictionary 
            $RuntimeParameterDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary            
        }
    }

    PROCESS {
        #Derived from
        # https://blogs.technet.microsoft.com/pstips/2014/06/09/dynamic-validateset-in-a-dynamic-parameter/

        # Perhaps check here if parameter name already exists in collection...
        # also check if parameter position is already occupied

        # Create the collection of attributes
        $AttributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $Mandatory
        if($ParameterPosition) {
            $ParameterAttribute.Position = $ParameterPosition
        }

        # Sätt eventuella properties i $ParameterAttribute som skickas in via $ExtraParameterProperties
        # Varje item (key) i $ExtraParameterProperties måste motsvara en property i klassen System.Management.Automation.ParameterAttribute
        Foreach($key in $ExtraParameterProperties.keys) {
            $ParameterAttribute.$key = $ExtraParameterProperties.$key
        }
        

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrset = Invoke-Expression -Command $FillValuesWith
        $ValidateSetAttribute = New-Object -TypeName System.Management.Automation.ValidateSetAttribute($arrset)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        #$RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [DynParamQuotedString], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        # Return the parameter
        return $RuntimeParameterDictionary
    }

    END {
    }
}
