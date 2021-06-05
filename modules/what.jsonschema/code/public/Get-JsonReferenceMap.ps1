function Get-ReferenceMap {
  [CmdletBinding()]
  param (
    [string]$Content
  )
  
  begin {
  }
  
  process {
    Foreach($line in $Content.split("`n"))
    {
      #regex = ^\s{0}\"\$ref\":\"(?'ref'.*)\"
      # "$ref":"referencevalue"
      if($Line -match "^\s{0}\""\`$ref\"":\""(?'ref'.*)\""")
      {
          $reference = $Matches['ref']
          

      }
    }
  }
  
  end {
    
  }
}