function Invoke-JsonSchemaToMarkdown {
  [CmdletBinding()]
  param (
    #either path to a directory or 
    [string]$Schema,
    [string]$OutputPath,
    [string]$Filter = "*.json"
  )
  
  begin {
    $global:JsonToMd = @{
      root = ""
      rootType = "" 
    }
    switch -Regex ($Schema)
    {
      "^http"{
          Write-Verbose "path is of type http"
          $root = $Schema
          $global:JsonToMd.rootType = "http"
      }
      default
    }
    # if($SchemaPath)
  }
  
  process {
    
  }
  
  end {
    
  }
}