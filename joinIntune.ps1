# Prompt user for Tenant ID
$guidKey = read-host "Please enter your Azure Tenant ID"

# Function to check if a service is running
function Is-ServiceRunning($serviceName)
{
  $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
  return $null -ne $service -and $service.Status -eq 'Running'
}

# Function to start a service and wait for 30 seconds
function Start-ServiceAndWait($serviceName)
{
  Start-Service $serviceName
  Start-Sleep -Seconds 30
}

# Variables for service check
$serviceName  = "dmwappushservice"
$maxAttempts  = 3
$attempts     = 0

# Check if the service is running
if (Is-ServiceRunning $serviceName)
{
  Write-Host "$serviceName is already running. Continuing with the script..."
} else
{
  # Attempt to start the service up to $maxAttempts times
  while ($attempts -lt $maxAttempts -and -not (Is-ServiceRunning $serviceName))
  {
    $attempts++
    Write-Host "$serviceName is not running. Attempting to start the service (Attempt $attempts)..."
    Start-ServiceAndWait $serviceName
  }

  # Check if the service started successfully
  if (Is-ServiceRunning $serviceName)
  {
    Write-Host "$serviceName has been started. Continuing with the script..."
  } else
  {
    Write-Host "Failed to start $serviceName after $maxAttempts attempts. Exiting script with error code 1001."
    exit 1001
  }
}

# Define the base registry path and GUID key
$basePath    = 'HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo'
$guidKeyPath = Join-Path $basePath $guidKey

# Ensure the base registry path exists. This is the path for Azure registrations
if (-not (Test-Path $basePath))
{
  Write-Host "Base registry path not found. Creating it..."
  try
  {
    New-Item -Path $basePath -Force | Out-Null
    Write-Host "Base path '$basePath' created successfully."
  } catch
  {
    Write-Host "Failed to create base path '$basePath': $_"
    exit 1
  }
} else
{
  Write-Host "Base path '$basePath' already exists."
}

# Ensure the specific GUID key exists. If its not there, create it.
if (-not (Test-Path $guidKeyPath))
{
  Write-Host "Key '$guidKeyPath' not found! Creating it..."
  try
  {
    New-Item -Path $guidKeyPath -Force | Out-Null
    Write-Host "Key '$guidKeyPath' created successfully."
  } catch
  {
    Write-Host "Failed to create key '$guidKeyPath': $_"
    exit 1
  }
} else
{
  Write-Host "Key '$guidKeyPath' already exists."
}

# Now check or create MDM Enrollment properties
try
{
  $mdmUrl = Get-ItemProperty -Path $guidKeyPath -Name 'MdmEnrollmentUrl' -ErrorAction SilentlyContinue
  if ($null -eq $mdmUrl)
  {
    throw "MDM Enrollment URL not found"
  }
} catch
{
  Write-Host "MDM Enrollment registry keys not found. Registering now..."
  # Define the MDM properties
  $mdmProperties = @{
    'MdmEnrollmentUrl'  = 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc'
    'MdmTermsOfUseUrl'  = 'https://portal.manage.microsoft.com/TermsofUse.aspx'
    'MdmComplianceUrl'  = 'https://portal.manage.microsoft.com/?portalAction=Compliance'
  }
  # Create or update the MDM properties
  foreach ($property in $mdmProperties.GetEnumerator())
  {
    New-ItemProperty -Path $guidKeyPath -Name $property.Key -Value $property.Value -PropertyType String -Force -ErrorAction SilentlyContinue
  }
} finally
{
  # Trigger AutoEnroll with the deviceenroller
  try
  {
    Write-Host "Updating group policies..."
    gpupdate /force

    Write-Host "Joining device to Azure AD..."
    dsregcmd /join /debug

    Write-Host "Triggering device enrollment..."
    & 'C:\Windows\system32\deviceenroller.exe' /c /AutoEnrollMDM

    Write-Host "Device is ready for Autopilot enrollment now!"
  } catch
  {
    Write-Host "Something went wrong with deviceenroller.exe"
    exit 1001
  }
}

# Ensure reg keys were added successfully, may take multiple tries.
dsregcmd /status
write-host "Please verify that the MdmUrl, MdmTouUrl, and MdmComplianceUrl fields are complete."
write-host "If they are blank, run the script repetitively until they are filled in."
# Unfortunately no way to check this automatically as the registry keys will be added physically so checks do not work.

# Exit script
exit 0

