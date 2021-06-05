function Invoke-FlattenJson
{
    [CmdletBinding()]
    [outputtype([System.Collections.Generic.List[JsonItem]])]
    param (
        [parameter(ValueFromPipeline)]
        [string]$json,
        $object,
        [string]$address = ""
    )
    
    begin
    {
        $OutArray = [System.Collections.Generic.List[JsonItem]]::new()
        if (!$object)
        {
            $converted = $json | convertfrom-json
        }
        else
        {
            $converted = $object
        }
    }
    
    process
    {
        # $converted.psobject.properties
        foreach ($property in $converted.psobject.properties)
        {
            $ThisPropertyAddress = (@($address, $property.name) | ? { $_ }) -join "."
            if ($property.value -is [array])
            {
                $out = [JsonItem]@{
                    name  = $ThisPropertyAddress
                    value = ""
                    type  = "Array"
                }
                $OutArray.add($out)
                # $OutArray += $out
                # Write-Output $out
                Write-log "Array $($property.name)" -level debug
                for ($i = 0; $i -lt $property.value.count; $i++)
                {
                    if ($property.value[$i] -is [array] -or $property.value[$i] -is [PSCustomObject])
                    {
                        #Create containter for array placement:
                        # [$i] = Array or Object
                        $out = [JsonItem]@{
                            name  = "$ThisPropertyAddress[$i]"
                            value = ""
                            type  = if ($property.value[$i] -is [array]) { "Array" }else { "Object" }
                        }
                        $OutArray.add($out)
                        # $OutArray += $out
                        # Write-Output $out

                        #Process children of array placement
                        # $processAddress = $((@($address,$property.name,"[$i]")|?{$_}) -join "."))
                        # Write-Output (Invoke-FlattenJson -json ($property.value[$i]|convertto-json -depth 20) -address "$ThisPropertyAddress[$i]")
                        (Invoke-FlattenJson -json ($property.value[$i] | convertto-json -depth 20) -address "$ThisPropertyAddress[$i]") | % {
                            $OutArray.Add($_)
                        }
                    }
                    else 
                    {
                        $out = [JsonItem]@{
                            name  = "$ThisPropertyAddress[$i]"
                            value = $property.value[$i]
                            type  = "item"
                        }
                        $OutArray.add($out)
                        # $OutArray += $out
                        # Write-Output $out
                    }
                }
            }
            elseif ($property.value -is [PSCustomObject])
            {
                $out = [JsonItem]@{
                    name  = $ThisPropertyAddress
                    value = ""
                    type  = "Object"
                }
                $OutArray.add($out)
                # $OutArray += $out
                # Write-Output $out

                Write-log "PSCustomObject $($property.name)" -level debug
                # Write-Output (Invoke-FlattenJson -json ($property.value|convertto-json -depth 20) -address $ThisPropertyAddress)
                (Invoke-FlattenJson -json ($property.value | convertto-json -depth 20) -address $ThisPropertyAddress) | % {
                    $OutArray.Add($_)
                }
            }
            else
            {
                Write-log "Other, $property; $($property.value)" -level debug
                $type = "Item"
                $out = [JsonItem]@{
                    name  = $ThisPropertyAddress
                    value = $property.value
                    type  = "Item"
                }
                $OutArray.add($out)
                # $OutArray += $out
                # Write-Output $out
            }
        }
    }
    
    end
    {
        return $OutArray #|select -Unique name,value,type
    }
}

# Invoke-FlattenJson -json (gc -raw "C:\Kildekode\Git\Zevs\definitions\schemas\action.json")
