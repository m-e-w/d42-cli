# d42-cli
(Unofficial) Device42 Command Line Interface (CLI) -- PowerShell
- 
- [1. Requirements](#1-requirements)
- [2. Installation](#2-installation)
  - [2.1 Clone the repostitory -- Recommended](#21-clone-the-repostitory----recommended)
  - [2.2. Open your PowerShell profile](#22-open-your-powershell-profile)
    - [2.2.1. (Visual Studio Code) -- Recommended](#221-visual-studio-code----recommended)
    - [2.2.2. (notepad) -- Not Recommended](#222-notepad----not-recommended)
  - [2.3. Copy and paste the following anywhere in your profile and replace the $d42_ values with your own](#23-copy-and-paste-the-following-anywhere-in-your-profile-and-replace-the-d42_-values-with-your-own)
  - [2.4. Close/Re-Open PowerShell](#24-closere-open-powershell)
  - [2.5. Now test to confirm the alias is working](#25-now-test-to-confirm-the-alias-is-working)
  - [2.6. Validate your config has loaded](#26-validate-your-config-has-loaded)
  - [2.7. Try it out](#27-try-it-out)
- [3. Commands](#3-commands)
  - [3.1. list config](#31-list-config)
  - [3.2. list building](#32-list-building)
  - [3.3. list device](#33-list-device)
  - [3.4. list rc](#34-list-rc)

# 1. Requirements
- PowerShell: 5.1.19041.1023 or >
- Device42: 17.02.00.1622225288 or >

It may still work with older versions but I cannot guarantee any backwards compatability.  

Tested with PowerShell Versions 5.1.19041.1023 & 7.1.3  
Tested with Device42 Verion: 17.02.00.1622225288

# 2. Installation

## 2.1 Clone the repostitory -- Recommended
    git clone https://github.com/m-e-w/d42-cli.git
    
If you'd prefer to download the zip, just keep in mind the $d42_cli_path_root (zip will append -main to the folder name)  

## 2.2. Open your PowerShell profile 
### 2.2.1. (Visual Studio Code) -- Recommended
Download Visual Studio Code here if you don't already have it: https://code.visualstudio.com/

Open PowerShell and type:  

    code $PROFILE

### 2.2.2. (notepad) -- Not Recommended
Open PowerShell and type:  

    $PROFILE

That is the pointer to your PowerShell profile.  
*Note* It doesn't necessarily need to exist. If you use the previous method, Visual Studio Code will automatically open your profile if it exists or make a new one for you at that location.

So instead, go to the directory specified  
Typically that's C:\Users\User\Documents\PowerShell\ or C:\Users\User\Documents\WindowsPowerShell  
Again, the PowerShell folder may not exist for you so if it doesn't, just create it. 

    mkdir WindowsPowerShell

Then create the profile file

    New-Item Microsoft.PowerShell_profile.ps1
    
Now open in notepad

    notepad $PROFILE

## 2.3. Copy and paste the following anywhere in your profile and replace the $d42_ values with your own

    # Device42 CLI Configuration Settings (Replace these with your own)
    $d42_cli_path_root = 'C:\Users\User\AppData\Local\d42-cli'
    $d42_host       =   '192.168.1.0'
    $d42_user       =   'admin'
    $d42_password   =   'adm!nd42'

    # Import the d42-cli script
    Import-Module -Name "$($d42_cli_path_root)\d42-cli.ps1"
    # Set the alias to call the Get-D42 function.
    Set-Alias d42 Get-D42

## 2.4. Close/Re-Open PowerShell

You may see a error stating:     

    File C:\Users\user\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 cannot be loaded because running scripts is disabled on this
    system. For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.

If that is the case, it's because you have execution policy set to restricted meaning you cannot run PowerShell scripts on the host. You can confirm that by typing:

    Get-ExecutionPolicy

To change the execution policy you will need to open powershell as an admin:

    Win Key + x (Windows PowerShell (Admin)
    
Now type:

    set-executionpolicy remotesigned
    
And hit A to confirm. 

If you want to read more about PowerShell exeuction policies, consult: https:/go.microsoft.com/fwlink/?LinkID=135170

## 2.5. Now test to confirm the alias is working

    d42 --help
    
You should see the following:  

    ----------How to Use----------

    There are 2 basic ways of calling a d42 cli command.

    1. d42 verb noun value
    2. d42 verb noun flag value

    Verbs
    list

    Nouns
    config device rc

    Tip: You can get more information on a verb-noun pair (as well as a list of all available flags/filters) like so:
    d42 list device --help

## 2.6. Validate your config has loaded
    d42 list config

## 2.7. Try it out
    d42 list device your_device

# 3. Commands
## 3.1. list config
    Description:
    List your current configuration.
## 3.2. list building
    Description:
    Lookup building(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.

    Flags:
    *Note: Only one flag can be used at a time*

    {
    "--all": "Return all records.",
    "--filter": "options: { address contact_name contact_phone }",
    "--exact": "Used to do a exact match instead of a partial match."
    }
## 3.3. list device
    Description:
    Lookup device(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.

    Flags:
    *Note: Only one flag can be used at a time*

    {
    "--all": "Return all records.",
    "--filter": "options: { os_name service_level type hw_model virtual_host ip object_category customer building }",
    "--exact": "Used to do a exact match instead of a partial match."
    }
## 3.4. list rc
    Description:
    Lookup remote rollector(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.

    Flags:
    *Note: Only one flag can be used at a time*

    {
    "--all": "Return all records.",
    "--filter": "options: { enabled connected state version ip }",
    "--exact": "Used to do a exact match instead of a partial match."
    }
