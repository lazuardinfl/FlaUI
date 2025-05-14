using namespace FlaUI.Core
using namespace FlaUI.Core.AutomationElements
using namespace FlaUI.Core.Definitions
using namespace FlaUI.Core.Input
using namespace FlaUI.Core.Tools
using namespace FlaUI.Core.WindowsAPI
using namespace System.Management.Automation

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

function Find-Element {
    [OutputType([FlaUI.Core.AutomationElements.AutomationElement])]
    param (
        [Alias("BaseElement")] [ValidateNotNullOrWhiteSpace()] [FlaUI.Core.AutomationElements.AutomationElement]$base,
        [Alias("FindBy")] [ValidateSet("Id", "XPath", "Custom")] [string]$by,
        [Alias("Element")] $value,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        $element = switch ($by) {
            "XPath" { $base.FindFirstByXPath($value) }
            { $by -in @("Id", "Custom") } { $base.FindFirstDescendant($value) }
            Default { throw [ValidationMetadataException] "Invalid find by type" }
        }
        if ($element) { return $element }
        else { throw "Element $($by) '$($value)' not found" }
    }
    catch { if ($silent) { return $null } else { throw } }
}

function Wait-Element {
    [OutputType([FlaUI.Core.AutomationElements.AutomationElement])]
    param (
        [Alias("BaseElement")] [ValidateNotNullOrWhiteSpace()] [FlaUI.Core.AutomationElements.AutomationElement]$base,
        [Alias("WaitMethod")] [ValidateSet("Appear", "Disappear")] [string]$method,
        [Alias("FindBy")] [ValidateSet("Id", "XPath", "Custom")] [string]$by,
        [Alias("Element")] $value,
        [Alias("TimeoutDuration")] [int]$timeout,
        [Alias("WaitAfter")] [int]$sleep,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        $msg = "Timeout after $($timeout) seconds, element $($by) '$($value)' not $($method.ToLower())"
        $found = switch ($method) {
            "Appear" {
                [Retry]::WhileNull[FlaUI.Core.AutomationElements.AutomationElement]({
                    $element = Find-Element $base $by $value
                    if ($element.GetClickablePoint() -and $element.IsEnabled -and !$element.IsOffscreen) { return $element }
                }, (New-TimeSpan -Seconds $timeout), (New-TimeSpan -Milliseconds 500), $true, $true, $msg).Result
            }
            "Disappear" {
                [Retry]::WhileFalse({
                    $element = Find-Element $base $by $value -OnErrorContinue
                    return ($null -eq $element) -or $element.IsOffscreen
                }, (New-TimeSpan -Seconds $timeout), (New-TimeSpan -Milliseconds 500), $true, $true, $msg).Result
            }
            Default { throw [ValidationMetadataException] "Invalid wait element method type" }
        }
        Start-Sleep -Seconds $sleep
        return $found
    }
    catch { if ($silent) { return $method -eq "Disappear" ? $false : $null } else { throw } }
}

function Invoke-Click {
    [OutputType([bool])]
    param (
        [Alias("BaseElement")] [ValidateNotNullOrWhiteSpace()] [FlaUI.Core.AutomationElements.AutomationElement]$base,
        [Alias("FindBy")] [ValidateSet("Id", "XPath", "Custom")] [string]$by,
        [Alias("Element")] $value,
        [Alias("Type")] [ValidateSet("Left", "LeftDouble", "Right", "RightDouble", "Legacy", "Invoke", "Select", "ToggleOn", "ToggleOff")] [string]$click,
        [Alias("WaitAfter")] [int]$sleep,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        $element = Find-Element $base $by $value
        $patterns = $element.Patterns
        switch ($click) {
            "Left" { $element.Click() }
            "LeftDouble" { $element.DoubleClick() }
            "Right" { $element.RightClick() }
            "RightDouble" { $element.RightDoubleClick() }
            "Invoke" { $patterns.Invoke.Pattern.Invoke() }
            "Select" { $patterns.SelectionItem.Pattern.Select() }
            "ToggleOn" { if ($patterns.Toggle.Pattern.ToggleState.Value -cne [ToggleState]::On) { $patterns.Toggle.Pattern.Toggle() } }
            "ToggleOff" { if ($patterns.Toggle.Pattern.ToggleState.Value -cne [ToggleState]::Off) { $patterns.Toggle.Pattern.Toggle() } }
            Default { $patterns.LegacyIAccessible.Pattern.DoDefaultAction() }
        }
        Start-Sleep -Seconds $sleep
        return $true
    }
    catch { if ($silent) { return $false } else { throw } }
}

function Set-Text {
    [OutputType([bool])]
    param (
        [Alias("BaseElement")] [ValidateNotNullOrWhiteSpace()] [FlaUI.Core.AutomationElements.AutomationElement]$base,
        [Alias("FindBy")] [ValidateSet("Id", "XPath", "Custom")] [string]$by,
        [Alias("Element")] $value,
        [Alias("TextInput")] [string]$text,
        [Alias("WaitAfter")] [int]$sleep,
        [Alias("EnterAfter")] [switch]$enter,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        [AutomationElementExtensions]::AsTextBox((Find-Element $base $by $value)).Enter($text)
        if ($enter) {
            Start-Sleep -Seconds 1
            [Keyboard]::Type([VirtualKeyShort]::ENTER)
        }
        Start-Sleep -Seconds $sleep
        return $true
    }
    catch { if ($silent) { return $false } else { throw } }
}
