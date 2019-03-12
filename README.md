# office365-devscripts
A collection of PowerShell Scripts for Office 365 and SharePoint.  The intention is to create a Script Framework that has the following benefits:
1. Automatically downloads CSOM libraries
2. Saves environment details in order to make calling scripts quicker
3. Passwords are stored encrypted for more security
4. Scripts are less convulted as common functions are moved into modules

# Important Concepts
- Call .\Start.ps1 to initialize the script framework
- The script framework encrypts the password and stores the details in the env subfolder in "Environment Files"
- The minimum parameters to call a script are normally: [Environment Name] [Environment Type]

The normal process of execution is to specify the following:
1. Environment Name
2. Environment Type (Dev, Test, UAT, Prod)

Example: .\Test-SPOConnection.ps1 Customer1 UAT

Environment details are stored within a .environment file in the env subfolder. 
The environment file contains all the values required to create a connection, such as siteUrl, username and password.
If the environment file can't be found, you will be asked to create a new one.

## Available Scripts & Commands
- Create-Environment.ps1 - Creates/Updates the environment files
- Get-Environments.ps1 - Gets all environment files
- Get-Environment - Loads a single environment
- Delete-ListItems.ps1 - Deletes all items from a list.  Works even if 5000 item limit has been hit.
- Get-CheckedOut.ps1 - Gets all items checked out from Master Pages and Style Library (Mine/All)
- Test-SPConnection.ps1 - Connects to SharePoint to confirm connectivity
- Set-ModernExperience.ps1 - Sets the modern experience enabled/disabled on a Site Collection
- Start.ps1 - Automatically called by the scripts to load required modules.  You can optionally call this when opening a new powershell window.
- Get-UserProfile.ps1 - Gets 1 or more profiles that match a specified parameter and outputs the User Profile Properties in SharePoint
