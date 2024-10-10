# Device Auto-Enrollment Script for MDM (Windows)

This PowerShell script automates the preparation and enrollment of a Windows device into Microsoft Intune. It ensures that necessary services are running, required registry keys are set, and triggers the device enrollment process. Devices can be joined from no Azure AD connection if they are domain joined, and your SCP is configured correctly with Azure AD Connect.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Usage Instructions](#usage-instructions)
- [Script Details](#script-details)
  - [Service Check and Start](#service-check-and-start)
  - [Registry Configuration](#registry-configuration)
  - [Triggering Device Enrollment](#triggering-device-enrollment)
- [Error Handling](#error-handling)
- [Notes](#notes)
- [License](#license)

## Overview

The script performs the following actions:

1. Checks if the **`dmwappushservice`** service is running and attempts to start it if it's not.
2. Ensures that specific registry keys required for MDM enrollment exist and creates them if they don't.
3. Updates group policies and triggers the device enrollment process using built-in Windows tools.

## Prerequisites

- **Operating System**: Windows 10 or later.
- **Permissions**: Must be run with administrative privileges.
- **Network Access**: The device should have internet access to reach the MDM enrollment URLs.
- **MDM Service**: Access to an MDM solution like Microsoft Intune.
- **Entra Hybrid Join**: For hybrid environments, Azure AD connect needs to be configured.
  
## Usage Instructions

1. **Open PowerShell as Administrator**:

   - Click on the **Start** menu.
   - Type `PowerShell`.
   - Right-click on **Windows PowerShell** and select **Run as administrator**.

2. **Save the Script**:

   - Copy the script code into a text editor.
   - Save the file with a `.ps1` extension, e.g., `EnrollDevice.ps1`.

3. **Execute the Script**:

   - Navigate to the directory where you saved the script.
   - Run the script using the following command:
     ```powershell
     .\EnrollDevice.ps1
     ```

4. **Follow On-Screen Prompts**:

   - The script will display progress messages.
   - Wait for the script to complete its execution.

## Script Details

### Service Check and Start

- **Service Name**: `dmwappushservice`
- **Functionality**:

  - Checks if the service is running.
  - If not, it attempts to start the service.
  - Retries up to **3 times**, waiting **30 seconds** between attempts.

- **Purpose**: This service is essential for the MDM enrollment process.

### Registry Configuration

- **Registry Base Path**:
  ```
  HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo
  ```
- **GUID Key**:
  ```
  This is your Azure Tenant ID
  ```
- **Registry Keys and Values**:

  - **`MdmEnrollmentUrl`**:
    ```
    https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc
    ```
  - **`MdmTermsOfUseUrl`**:
    ```
    https://portal.manage.microsoft.com/TermsofUse.aspx
    ```
  - **`MdmComplianceUrl`**:
    ```
    https://portal.manage.microsoft.com/?portalAction=Compliance
    ```

- **Functionality**:

  - Ensures the base registry path exists; creates it if it doesn't.
  - Ensures the specific GUID key exists; creates it if it doesn't.
  - Checks for the `MdmEnrollmentUrl` property; adds it along with other MDM properties if missing.

### Triggering Device Enrollment

- **Update Group Policies**:
  ```powershell
  gpupdate /force
  ```
- **Join Device to Azure AD**:
  ```powershell
  dsregcmd /join /debug
  ```
- **Trigger Device Enrollment**:
  ```powershell
  C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDM
  ```

- **Functionality**:

  - Forces a group policy update to ensure the latest policies are applied.
  - Joins the device to Azure Active Directory.
  - Initiates the MDM auto-enrollment process.

## Error Handling

- **Service Start Failure**:

  - If the `dmwappushservice` fails to start after 3 attempts, the script exits with error code **`1001`**.

- **Registry Access Errors**:

  - If the script cannot create necessary registry keys, it exits with error code **`1`**.

- **Device Enrollment Failure**:

  - If `deviceenroller.exe` encounters an error, the script exits with error code **`1001`**.

- **General Exceptions**:

  - The script uses try-catch blocks to handle exceptions and will display relevant error messages before exiting.

## Notes

- **Administrative Rights**: The script must be run as an administrator to modify services and registry entries.
- **Testing**: It is recommended to test the script in a controlled environment before deploying it broadly.
- **Compatibility**: While designed for Windows 10 and later, ensure compatibility with your specific environment.

## License

This script is provided "as-is" without any warranty or guarantee. Use it at your own risk. The author is not responsible for any damage or data loss resulting from the use of this script.

---

**Disclaimer**: Always ensure you understand a script's functionality before running it, especially when it involves system services and registry modifications.
