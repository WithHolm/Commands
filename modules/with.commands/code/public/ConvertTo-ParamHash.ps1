# using module PSOneTools

function Convert-HashtableToString
{
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [System.Management.Automation.PSToken[]]$HashTokens,
        [int]$Index,
        [switch]$Compress,
        [switch]$IsTypeCasting
    )
    $depth = 0
    $HashContent = @()
    $hashstart = $null
    :hashloop for ($i = $Index; $i -lt $HashTokens.Count; $i++)
    {
        $currToken = $HashTokens[$i]
        if ($IsTypeCasting -and $currToken.Content -like "*@")
        {
            $hashstart = $currToken.Content, $HashTokens[$i + 1].Content -join ""
            Write-Verbose "Got start of hashtable: '$hashstart'"
            $i = $i + 1
            $depth++
        }
        elseif ($currToken.Content -eq "@{")
        {
            # Write-Verbose "Got start of hashtable"
            $hashstart = $currToken.Content
            Write-Verbose "Got start of hashtable: '$hashstart'"
            $depth++
        }
        elseif ("LineContinuation", "Newline", 'StatementSeparator' -eq $currToken.Type)
        {
            #skip
        }
        elseif ($currToken.Content -like "*{*")
        {
            $depth++
        }
        elseif ($currToken.Content -like "*}*")
        {
            $depth--
            if ($depth -eq 0)
            {
                Write-Verbose "End of hashtable. returning"
                break :hashloop
            }
        }
        elseif ($currToken.type -eq 'Member')
        {
            Write-Verbose ("hashtable member: '{0}'" -f $currToken.Content)
            $HashContent += "{0}" -f $currToken.Content
        }
        else
        {
            Write-Verbose ("depth:$depth Content type:'{0}', content:'{1}'" -f $currToken.Type, $currToken.Content)
            # Write-Verbose ("Content type:'{0}', content:'{1}'" -f $currtok.Type, $currtok.Content)
            $content = $currToken.Content
            if ($content[-1] -eq '`')
            {
                $content = $content.Substring(0, ($content.Length - 1))
            }
            if ($currToken.Type -eq 'string')
            {
                $content = '"{0}"' -f $content
            }
            elseif ($currToken.type -eq 'variable')
            {
                $content = '${0}' -f $content
            }

            try
            {
                $HashContent[-1] += $content
            }
            catch
            {
                throw "Failed to generate hashtable object to string output. expected 'Member', but got '$($currToken.Type)'. is the input correct? (try adding () around the hash or object definition)"
            }
            # $HashContent[-1] += $currToken.Content
        }
    }

    $outcontent = @()
    if ($Compress)
    {
        $outcontent = @($hashstart, $($HashContent -join "; "), "}" -join "")
    }
    else
    {
        $outcontent += $hashstart
        $HashContent | ForEach-Object {
            $outcontent += "  $_"
        }
        $outcontent += "}"
    }

    return @{
        content = $outcontent
        Index   = $i
    }
}
function ConvertTo-ParamHash
{
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        $InputItem,
        [switch]$CompressHashValues
    )
    begin {}
    process
    {
        if ($InputItem -is [scriptblock])
        {
            $InputItem = $InputItem.tostring()
        }

        $code = $InputItem -join "`n"
        $errors = $null
        $tokens = [System.Management.Automation.PSParser]::Tokenize($code, [ref]$errors)

        # analyze errors:
        if ($errors.Count -gt 0)
        {
            # move the nested token up one level so we see all properties:
            $syntaxError = $errors | Select-Object -ExpandProperty Token -Property Message
            $syntaxError
        }
        else
        {
            $command = ""
            $ParamArr = @(
                '$param = @{'
            )
            # return $tokens
            # $CurrentParam = @()
            for ($i = 0; $i -lt $tokens.Count; $i++)
            {
                $currtok = $tokens[$i]
                # 
                
                #Define the command token (ie 'get-module' or the like) if its not yet defined. 
                if ($currtok.Type -eq 'command' -and [string]::IsNullOrEmpty($command))
                {
                    $command = $currtok.Content
                    $CommandParameters = (get-command $command).Parameters 
                }
                #Define command parameter token as a new line in the array
                elseif (
                    $currtok.Type -eq 'CommandParameter' -and 
                    $CommandParameters.($currtok.Content.substring(1).Replace(":", ""))
                )
                {
                    $thisparamName = $currtok.Content.substring(1).Replace(":", "")
                    $ThisParamDetail = $CommandParameters.($thisparamName)
                    Write-Verbose ("**Parameter: {0}" -f $thisparamName)
                    $ParamArr += "    {0}=" -f $thisparamName
                    if ('SwitchParameter' -eq $ThisParamDetail.parametertype.name -and $tokens[$i + 1].type -eq "CommandParameter")
                    {
                        Write-Verbose "Parameter is of type switch. adding $true"
                        $ParamArr[-1] += '$true'
                    }
                }
                elseif ("LineContinuation", "Newline" -eq $currtok.Type)
                {
                    #skip
                }
                elseif ($currtok.Content -eq "@{")
                {
                    Write-Verbose "Handling hashtable"
                    $hashItems = Convert-HashtableToString -HashTokens $tokens -Index $i -Compress:$CompressHashValues.IsPresent
                    $ParamArr[-1] += $hashItems.content[0]
                    $hashItems.content | select -Skip 1 | % {
                        $ParamArr += "`t$_"
                    }
                    $i = $hashItems.index
                }
                elseif ($currtok.type -eq "CommandArgument" -and $currtok.Content -like "*@" -and $tokens[$i + 1].content -eq '{' )
                {
                    Write-Verbose "Handling hashtable cast to $($currtok.Content.Substring(0,($currtok.Content.Length-1)))"
                    $hashItems = Convert-HashtableToString -HashTokens $tokens -Index $i -IsTypeCasting -Compress:$CompressHashValues.IsPresent
                    
                    #add first line of return to content. add rest as new lines, if there are more lines
                    $ParamArr[-1] += $hashItems.content[0]
                    $hashItems.content | select -Skip 1 | % {
                        $ParamArr += "`t$_"
                    }
                    $i = $hashItems.index
                }
                #add data to last line of array
                else
                {
                    Write-Verbose ("Content type:'{0}', content:'{1}'" -f $currtok.Type, $currtok.Content)
                    $content = $currtok.Content
                    if ($content[-1] -eq '`')
                    {
                        $content = $content.Substring(0, ($content.Length - 1))
                    }
                    if ($currtok.Type -eq 'string')
                    {
                        $content = '"{0}"' -f $content
                    }
                    elseif ($currtok.type -eq 'variable')
                    {
                        $content = '${0}' -f $content
                    }

                    $ParamArr[-1] = $ParamArr[-1], $content -join " "
                }
            }
            $paramArr += "}"
            $ParamArr += "$command @param"
            $ParamArr
        }
    }
    end {}
}


$code = {
    get-module -Name "testing"`
        -FullyQualifiedName (join-path "test" "path") `
        -Refresh @{
        test = "value"
        other = "value"; value = "jepp"
    } `
        -ListAvailable:$false
} 
Write-host "Input $code"

Write-host "output"
$code | ConvertTo-ParamHash -Verbose

