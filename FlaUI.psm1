using namespace FlaUI.Core

function Get-UIA {
    [OutputType([FlaUI.Core.AutomationBase])]
    param ()
    switch ($env:FlaUIVersion) {
        "UIA2" { return [FlaUI.UIA2.UIA2Automation]::new() }
        Default { return [FlaUI.UIA3.UIA3Automation]::new() }
    }
}

function Get-ApplicationWindow {
    [OutputType([FlaUI.Core.AutomationElements.Window])]
    param (
        [Alias("ApplicationProcess")] [ValidateNotNullOrWhiteSpace()] $app,
        [Alias("AutomationUIA")] [ValidateNotNullOrWhiteSpace()] [FlaUI.Core.AutomationBase]$uia,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        $window = [Application]::Attach($app).GetMainWindow($uia)
        if ($window) { return $window }
        else { throw "Application main window not found" }
    }
    catch { if ($silent) { return $null } else { throw } }
}
