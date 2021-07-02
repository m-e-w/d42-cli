# d42-cli
(Unofficial) Device42 Command Line Interface (CLI) -- PowerShell

## Requirements
- PowerShell: 5.1.19041.1023 or >
- Device42: 17.02.00.1622225288 or >

It may still work with older versions but I cannot guarantee any backwards compatability.  

Tested with PowerShell Versions 5.1.19041.1023 & 7.1.3  
Tested with Device42 Verion: 17.02.00.1622225288

# Installation

## 00:  Clone the repostitory -- Recommended
    git clone https://github.com/m-e-w/d42-cli.git
    
If you'd prefer to download the zip, just keep in mind the $d42_cli_path_root (zip will append -main to the folder name)  

## 01:  Open your PowerShell profile 
###         (Visual Studio Code) -- Recommended
Download Visual Studio Code here if you don't already have it: https://code.visualstudio.com/

Open PowerShell and type:  

    code $PROFILE

###         (notepad) -- Not Recommended
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

## 02:  Copy and paste the following anywhere in your profile and replace the $d42_ values with your own

    # Device42 CLI Configuration Settings (Replace these with your own)
    $d42_cli_path_root = 'C:\Users\User\AppData\Local\d42-cli'
    $d42_host       =   '192.168.1.0'
    $d42_user       =   'admin'
    $d42_password   =   'adm!nd42'

    # Import the d42-cli script
    Import-Module -Name "$($d42_cli_path_root)\d42-cli.ps1"
    # Set the alias to call the Get-D42 function.
    Set-Alias d42 Get-D42

## 03:  Close/Re-Open PowerShell

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

## 04:  Now test to confirm the alias is working

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

## 05:  Validate your config has loaded
    d42 list config

## 06:  Try it out
    d42 list device your_device

See the list below for commands

# Commands

## list config
List your current config details. 
### Example
    d42 list config

## list device 
    Description:
            Lookup device(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more devices.

    Flags:
            (Note: Only one flag can be used at a time)

            --exact
                    Used to do a exact match instead of a partial match.

            --filter
                    Used to specify a filter. Only one filter can be used at a time and only EQUALS ( = ) comparisons are currently supported.

                    Filters:
                            os_name service_level type hw_model virtual_host ip object_category customer building

    Examples:
            d42 list device esxi-9000
            d42 list device --exact esxi-9000.lab.pvt
            d42 list device --filter ip=192.168.1.0
            d42 list device --filter building='Los Angeles'

## list rc
List all Remote Collectors.
### Example
    d42 list rc
