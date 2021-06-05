class JsonFile{
    [System.Collections.Generic.List[JsonItem]]$List
    [string]$Path
    JsonFile(){}
    [string] SchemaPath()
    {
        $schemaitem = $this.list|?{$_.Name -eq '$schema'}
        if(!$schemaitem)
        {
            write-log -Level Throw -message "cannot find a reference to '`$schema' object in the json"
        }
        if($schemaitem.Value -like "./*")
        {
            $location = get-location
            set-location (split-path $this.Path)
            $item = get-item $schemaitem.Value -ErrorAction Stop
            $return = $item.FullName
            Set-Location $location
        }
        elseif($schemaitem.Value -like "file:*")
        {
            $return = $schemaitem.Value.Substring(5)
        }
        else {
            $return = $schemaitem.Value
        }
        return $return
    }

}

class JsonItem{
    [string]$Name
    [string]$Value
    [string]$type
    hidden $VarRegex = "\$\{(?'scope'env|script|global|arg)\:(?'varname'[a-zA-Z0-9._-]{3,})\}"

    [bool]isref()
    {
        if($this.type -notlike "Item")
        {
            return $false
        }
        elseif($this.name -like "*`$ref")
        {
            return $true
        }
        return $false
    }

    [string]asReferencePrefix()
    {
        $returnAddressArray = $this.name.split(".")|ForEach-Object{$_.replace('$ref',"")}

        return (($returnAddressArray|?{![string]::IsNullOrEmpty($_)}) -join ".")
    }

    [string] ToString()
    {
        # switch($this.type)
        # {
        #     if($item)
        # }
        # $value = $this.Value
        # if()
        return """$($this.Name)"":""$($this.Value)"""
    }
    # [bool]HasVariable()
    # {
    #     return ($this.Value -match $this.VarRegex)
    # }

    # [string]GetVariableNames()
    # {
    #     $return = @()
    #     foreach ($Match in [regex]::Matches($this.value, $this.VarRegex))
    #     {
    #         #return items in array that does not have the automatically assigned numbers as names and join with :
    #         $return += @(($match.Groups|?{$_.name -notmatch "[0-9]"}).Value -join ":")
    #     }
    #     return $return
    # }
}

# $item = [JsonItem]@{
#     type = "item"
#     Name = '$ref'
#     value = "eyy"
# }

# $item.asReferencePrefix()
