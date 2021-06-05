Describe "ConvertTo-ParamHash"{
    BeforeDiscovery {
        $TestCases = @(
            @{
                Q = 'get-module -Name "Something" -FullyQualifiedName "SomethingElse" -All -ListAvailable'
                A = 
            }
        )
    }
}