$NuGetUrl = "https://api.nuget.org/v3/index.json"
$Resources = [System.Collections.ArrayList]::new()
$Resources.Add(@{ Name = "FlaUI.Core"; Version = "5.0.0"; Import = @("lib\net8.0-windows7.0\FlaUI.Core.dll") }) | Out-Null
switch ($env:FlaUIVersion) {
    "UIA2" {
        $Resources.Add(@{ Name = "FlaUI.UIA2"; Version = "5.0.0"; Import = @("lib\net8.0-windows7.0\FlaUI.UIA2.dll") }) | Out-Null
    }
    Default {
        $Resources.Add(@{ Name = "Interop.UIAutomationClient"; Version = "10.19041.0"; Import = @("lib\netcoreapp3.0\Interop.UIAutomationClient.dll") }) | Out-Null
        $Resources.Add(@{ Name = "FlaUI.UIA3"; Version = "5.0.0"; Import = @("lib\net8.0-windows7.0\FlaUI.UIA3.dll") }) | Out-Null
    }
}
try {
    # install
    foreach ($resource in $Resources) {
        if (!(Get-InstalledPSResource -Name $resource.Name -Version $resource.Version -ErrorAction SilentlyContinue)) {
            if (!(Get-PSResourceRepository | Where-Object { $_.Uri -eq $NuGetUrl })) {
                Register-PSResourceRepository -Name NuGetGallery -Uri $NuGetUrl -Priority 80 -Trusted -Force -ErrorAction Stop
            }
            Install-PSResource $resource.Name -Version "[$($resource.Version)]" -Scope CurrentUser -TrustRepository -AcceptLicense -SkipDependencyCheck -ErrorAction Stop
        }
    }
    # import
    foreach ($resource in $Resources) {
        $path = (Get-InstalledPSResource -Name $resource.Name -Version $resource.Version -ErrorAction Stop).InstalledLocation
        foreach ($item in $resource.Import) {
            Import-Module "$($path)\$($resource.Name)\$($resource.Version)\$($item)" -Global -Force -ErrorAction Stop
        }
    }
}
catch { throw }
