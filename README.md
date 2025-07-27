# install_required_apps

A simple PowerShell script to automate the installation of required applications on your Windows machine.

## Overview

This repository contains a PowerShell script designed to streamline the setup process for a new Windows environment. By defining a list of essential applications, the script ensures that all required software is installed quickly and efficiently, saving you valuable time.

## Features

-   **Automated Application Installation:** Installs a predefined set of applications using PowerShell.
-   **Customizable:** Easily modify the script to add or remove applications as per your needs.
-   **User-Friendly:** Minimal user interaction required.
-   **Repeatable:** Can be used every time you set up a new machine or refresh your environment.

## Prerequisites

-   Windows 10 or above
-   PowerShell 5.0 or later
-   Administrator privileges

## Enabling Script Execution

By default, PowerShell restricts the execution of scripts for security reasons. To run this script for the first time, you must change the execution policy:

1. Open PowerShell as **Administrator**.
2. Run the following command:

    ```powershell
    Set-ExecutionPolicy RemoteSigned
    ```

3. When prompted, type `Y` and press Enter to confirm.

This allows you to run local scripts and remote scripts that are digitally signed.

## Usage

1. **Clone the Repository:**

    ```bash
    git clone https://github.com/subhadip6869/install_required_apps.git
    cd install_required_apps
    ```

2. **Review the Script:**

    - Open the PowerShell script file (e.g., `install_required_apps.ps1`) in your preferred editor.
    - Edit the list of applications as needed.

3. **Run the Script:**
    - Launch PowerShell **as Administrator**.
    - Execute the script:
        ```powershell
        .\windows.ps1
        ```
    - Follow any prompts that appear.

## Disclaimer

This script is provided as-is. Use at your own risk. Make sure you review and understand the script before running it on your system.

---

**Author:** [subhadip6869](https://github.com/subhadip6869)
