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

## Available Scripts
TODO:

