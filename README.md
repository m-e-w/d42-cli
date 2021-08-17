# d42-cli
(Unofficial) Device42 Command Line Interface (CLI) -- PowerShell

- [Changelog](#changelog)
- [Requirements](#requirements)
- [Installation](#installation)
- [Commands](#commands)
  - [list config](#list-config)
  - [list building](#list-building)
  - [list dd](#list-dd)
  - [list device](#list-device)
  - [list rc](#list-rc)
  - [list room](#list-room)
- [Resources](#resources)
  - [Videos](#videos)
  - [Links](#links)

# Changelog
## v 0.06 | 2021-08-17
m-e-w: Deprecating support for PowerShell 5.1 until https://github.com/m-e-w/d42-cli/issues/1 can be reviewed. Will need to review how to keep backwards compatability with older PowerShell versions in the future but for now will update requirements to specify PowerShell 7.0 at the minimum.

m-e-w: Updated license agreement.

# Requirements
- PowerShell 7.0 or >
- Device42 17.0 or >

It may still work with older versions but I cannot guarantee any backwards compatability.  

# Installation

## 1. Clone the repostitory -- Recommended
    git clone https://github.com/m-e-w/d42-cli.git
    
If you'd prefer to download the zip, just keep in mind the $d42_cli_path_root (zip will append -main to the folder name)  

## 2. Open your PowerShell profile 
### 2.1. (Visual Studio Code) -- Recommended
Download Visual Studio Code here if you don't already have it: https://code.visualstudio.com/

Open PowerShell and type:  

    code $PROFILE

### 2.2. (notepad) -- Not Recommended
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

## 3. Copy and paste the following anywhere in your profile and replace the $d42_ values with your own

    # Device42 CLI Configuration Settings (Replace these with your own)
    $d42_cli_path_root = 'C:\Users\User\AppData\Local\d42-cli'
    $d42_host          = '192.168.1.0'
    $d42_user          = 'admin'
    $d42_password      = 'adm!nd42'
    $d42_debug         = $false

    # Import the d42-cli script
    Import-Module -Name "$($d42_cli_path_root)\d42-cli.ps1"
    # Set the alias to call the Get-D42 function.
    Set-Alias d42 Get-D42

## 4. Close/Re-Open PowerShell

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

If you want to read more about PowerShell exeuction policies, consult: https://go.microsoft.com/fwlink/?LinkID=135170

## 5. Now test to confirm the alias is working

    d42 --help
    
You should see the following:  
```
{
  "description": "(Unofficial) Device42 Command Line Interface (CLI) -- PowerShell",
  "version": "0.05",
  "approved_verbs": [
    "list"
  ],
  "approved_nouns": [
    "building",
    "config",
    "dd",
    "device",
    "rc",
    "room"
  ]
}
```

## 6. Validate your config has loaded
    d42 list config

## 7. Try it out
    d42 list device your_device

# Commands
## list config
```
{
  "description": "List your current configuration"
}
```
## list building
```
{
  "description": "Lookup building(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.",
  "flags": {
    "--all": {
      "description": "Return all records."
    },
    "--exact": {
      "description": "Used to do a exact match instead of a partial match."
    },
    "--filter": {
      "description": "Used to filter results.",
      "filters": [
        "address",
        "contact_name",
        "contact_phone"
      ]
    }
  }
}
```
## list dd
```
{
  "description": "Lookup columns in the data dictionary by view (current version: 17.03)",
  "type": "local",
  "flags": {
    "--views": {
      "description": "Only list views. Not columns."
    }
  }
}
```
## list device
```
{
  "description": "Lookup device(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.",
  "flags": {
    "--all": {
      "description": "Return all records."
    },
    "--exact": {
      "description": "Used to do a exact match instead of a partial match."
    },
    "--filter": {
      "description": "Used to filter results.",
      "filters": [
        "os_name",
        "service_level",
        "type",
        "hw_model",
        "virtual_host",
        "ip",
        "object_category",
        "customer",
        "building"
      ]
    }
  }
}
```
## list rc
```
{
  "description": "Lookup remote collector(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.",
  "flags": {
    "--all": {
      "description": "Return all records."
    },
    "--exact": {
      "description": "Used to do a exact match instead of a partial match."
    },
    "--filter": {
      "description": "Used to filter results.",
      "filters": [
        "enabled",
        "state",
        "version",
        "ip"
      ]
    }
  }
}
```
## list room
```
{
  "description": "Lookup room(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.",
  "flags": {
    "--all": {
      "description": "Return all records."
    },
    "--exact": {
      "description": "Used to do a exact match instead of a partial match."
    },
    "--filter": {
      "description": "Used to filter results.",
      "filters": []
    }
  }
}
```

# Resources
## Videos
### How to Add a New Command
[![How to Add a New d42-cli Command](https://img.youtube.com/vi/j0BDHmA26iI/0.jpg)](https://www.youtube.com/watch?v=j0BDHmA26iI)
## Links
- https://www.device42.com/
- https://docs.device42.com/device42-doql/
- https://docs.microsoft.com/en-us/powershell/

