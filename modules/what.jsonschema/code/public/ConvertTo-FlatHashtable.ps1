function ConvertTo-FlatHashtable {
  [CmdletBinding()]
  param (
    # Parameter help description
  [Parameter(ValueFromPipeline)]
  $InputObject,
  
  [string]$Address
  )
  begin {
    
  }
  
  process {
    if($Address)
    {
      $Address.split(".")|%{
        $InputObject = $InputObject.$_
      }
    } 
    if($InputObject -is $array)
    {
      
    }
  }
  
  end {
    
  }
}