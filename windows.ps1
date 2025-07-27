# Check for Administrator privileges and re-launch as admin if needed
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..."
    # Relaunch this script as administrator with -NoExit to keep the window open after execution
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Function to safely add a directory to the system PATH
function Add-ToSystemPath($pathToAdd) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    if (!($currentPath.Split(";") -contains $pathToAdd)) {
        $newPath = ($currentPath.TrimEnd(';') + ";" + $pathToAdd)
        [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
        # Update current session PATH variable (optional)
        $env:Path = $newPath
        Write-Host "Added $pathToAdd to the system PATH."
    }
    else {
        Write-Host "The directory $pathToAdd is already in the system PATH."
    }
}

function Add-SystemVariable($variableName, $variableValue) {
    $currentValue = [Environment]::GetEnvironmentVariable($variableName, [EnvironmentVariableTarget]::Machine)
    if ($currentValue -ne $variableValue) {
        [Environment]::SetEnvironmentVariable($variableName, $variableValue, [EnvironmentVariableTarget]::Machine)
        Write-Host "Added $variableName with value $variableValue to the system environment."

        # Update current session variable (optional)
        Set-Item -Path "env:$variableName" -Value $variableValue
    }
    else {
        Write-Host "The variable $variableName is already set to $variableValue."
    }
}

function Invoke-PowerShellProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,    # The command/script block to execute as a string
        [switch]$AsAdmin     # Optional: run the new process elevated if specified
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -Command `"$Command`""
    $psi.UseShellExecute = $true

    if ($AsAdmin) {
        $psi.Verb = "runas"  # Run as administrator
    }

    try {
        $process = [System.Diagnostics.Process]::Start($psi)
        $process.WaitForExit()
        Write-Host "Command executed successfully in new PowerShell process."
    }
    catch {
        Write-Warning "Failed to execute command in new PowerShell process: $_"
    }
}

# Define an array of software installers with URLs and silent install options
$softwareList = @(
    @{
        Name          = "Sublime Text"
        Url           = "https://download.sublimetext.com/sublime_text_build_4200_x64_setup.exe"
        InstallerPath = "$env:TEMP\sublime_text_setup.exe"
        Group         = "common"
        Arguments     = "/VERYSILENT /NORESTART /TASKS=contextentry"
        PostInstall   = {
            Add-ToSystemPath "C:\Program Files\Sublime Text"
        }
    },
    @{
        Name          = "Visual Studio Code"
        Url           = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
        InstallerPath = "$env:TEMP\vscode_installer.exe"
        Group         = "common"
        Arguments     = "/VERYSILENT /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,desktopicon"
    },
    @{
        Name          = "Java 17 (Oracle)"
        Url           = "https://download.oracle.com/java/17/archive/jdk-17.0.12_windows-x64_bin.exe"
        InstallerPath = "$env:TEMP\jdk-17.0.12_windows-x64_bin.exe"
        Group         = "dev"
        Arguments     = "/s"
        PostInstall   = {
            $jdkRoot = "C:\Program Files\Java\jdk-17"
            $jdkBin = Join-Path $jdkRoot "bin"

            Add-ToSystemPath $jdkBin
            Add-SystemVariable "JAVA_HOME" $jdkRoot
        }
    },
    @{
        Name          = "WinRAR"
        Url           = "https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-712.exe"
        InstallerPath = "$env:TEMP\winrar_setup.exe"
        Group         = "common"
        Arguments     = "/S"  # Silent install switch for WinRAR
    }
)

# Separate array for winget installs
$wingetList = @(
    @{
        Id          = "Git.Git"
        Name        = "Git for Windows"
        Group       = "common"
        PostInstall = {
            Invoke-PowerShellProcess -Command "git config --system init.defaultbranch main"
            Write-Host "Set Git global default branch to main."
        }
    },
    @{
        Id    = "OpenJS.NodeJS.LTS"
        Name  = "Node.js"
        Group = "common"
    },
    @{
        Id    = "Python.Python.3.12"
        Name  = "Python 3.12"
        Group = "common"
    },
    @{
        Id    = "Google.Chrome"
        Name  = "Google Chrome"
        Group = "common"
    },
    @{
        Id    = "Mozilla.Firefox"
        Name  = "Mozilla Firefox"
        Group = "common"
    },
    @{
        Id    = "Postman.Postman"
        Name  = "Postman"
        Group = "dev"
    },
    @{
        Id    = "Google.AndroidStudio"
        Name  = "Android Studio"
        Group = "dev"
    },
    @{
        Id    = "Microsoft.Office"
        Name  = "Microsoft Office 365"
        Group = "db|rpa"
    },
    @{
        Id    = "Microsoft.FuzzyLookupAddExcel"
        Name  = "Fuzzy Lookup Add-In for Excel"
        Group = "db|rpa"
    },
    @{
        Id    = "Oracle.MySQL"
        Name  = "MySQL"
        Group = "db|dev"
    }
)

function Install-Softwares($selectedGroup) {
    # ----- Main script starts here -----
    Write-Host "Starting installation of software for group: $selectedGroup"
    foreach ($app in $softwareList) {
        if ($app.Group.Split("|") -contains $selectedGroup -or $app.Group.Split("|") -contains "common") {
            try {
                Write-Host "Downloading $($app.Name) from $($app.Url) ..."
                Invoke-WebRequest -Uri $app.Url -OutFile $app.InstallerPath -ErrorAction Stop

                Write-Host "Installing $($app.Name) silently with options: $($app.Arguments)"
                Start-Process -FilePath $app.InstallerPath -ArgumentList $app.Arguments -Wait -ErrorAction Stop

                Write-Host "Cleaning up installer for $($app.Name)..."
                Remove-Item -Path $app.InstallerPath -Force -ErrorAction SilentlyContinue

                # Run optional post-install scriptblock if defined
                if ($null -ne $app.PostInstall) {
                    Write-Host "Running post-install actions for $($app.Name)..."
                    & $app.PostInstall
                }

                Write-Host "$($app.Name) installed successfully.`n"
            }
            catch {
                Write-Warning "An error occurred during the process for $($app.Name): $_"
                # Optional: Cleanup in case of partial download or install
                if (Test-Path $app.InstallerPath) {
                    try {
                        Remove-Item -Path $app.InstallerPath -Force -ErrorAction SilentlyContinue
                        Write-Host "Cleaned up installer file for $($app.Name) after error."
                    }
                    catch {
                        Write-Warning "Could not remove installer file for $($app.Name): $_"
                    }
                }
                # Continue with next software
            }
        }
    }

    foreach ($wingetApp in $wingetList) {
        if ($wingetApp.Group.Split("|") -contains $selectedGroup -or $wingetApp.Group.Split("|") -contains "common") {
            try {
                Write-Host "Installing $($wingetApp.Name) via winget..."
                winget install --id $wingetApp.Id -e --source winget --accept-source-agreements --accept-package-agreements

                # Run postinstall scriptblock if provided
                if ($null -ne $wingetApp.PostInstall) {
                    & $wingetApp.PostInstall
                }
                Write-Host "$($wingetApp.Name) installed successfully.`n"
            }
            catch {
                Write-Warning "An error occurred during winget install for $($wingetApp.Name): $_"
            }
        }
    }

    Write-Host "Installation of all applications complete."
    Write-Host "Press Enter to exit."
    Read-Host
}

# Define software groups
$validGroups = @("exit", "common", "dev", "db", "rpa")

# Prompt user to select groups
Write-Host "Please select one or more software groups to install (comma separated):"
for ($i = 0; $i -lt $validGroups.Count; $i++) {
    Write-Host "$($i). $($validGroups[$i])"
}

do {
    $selection = Read-Host "Enter group number (0-$($validGroups.Count - 1))"
    if ($selection -eq '0') {
        Write-Host "Exiting script by user request."
        exit
    }
    $selectedGroup = $validGroups[$selection]
    if ($validGroups -contains $selectedGroup) {
        Install-Softwares -selectedGroup $selectedGroup
    }
} while (!($validGroups -contains $selectedGroup))