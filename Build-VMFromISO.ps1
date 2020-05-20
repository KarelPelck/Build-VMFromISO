Function  Build-VMFromISO {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
    #>
    Param (
        #Path of the ISO
        [parameter (Mandatory=$true)]
        [String]$ISOPath,
        #Path to store your VM and Virtual disk
        [parameter (Mandatory=$true)]
        [String]$VMsPath,
        #VMName
        [parameter (Mandatory=$true)]
        [String]$VMName,
        #DiskSize
        [parameter (Mandatory=$true)]
        [Int64]$Size,
        #MemorySize
        [parameter (Mandatory=$true)]
        [Int64]$Memory
    ) 



    try {
        

        #Check for needed modules and install if not found

        $modules = @(
            "WindowsImageTools"
        )

        $VMFolderPath = $VMsPath + $VMName
        $VMDiskPath = $VMFolderPath + "\Disk.VHDX"

        foreach ($m in $modules) {
            if (!(get-module "$m*" -ListAvailable)) {
                Write-Host "Installing $m module to currentUser.."
                Install-Module -Name $m -Scope CurrentUser -Force
            } else {
                Write-Host "$m module is already available!"
            }
        }

        $mount = Mount-DiskImage -ImagePath $IsoPath
        $volume = $mount | Get-Volume
        $ImageSearchPath = $Volume.driveletter + ":\Sources\install.*"
        $ImagePath = (Get-ChildItem -Path $ImageSearchPath).FullName
        $edition = Get-WindowsImage -ImagePath $ImagePath | Out-GridView -PassThru -Title "Select an edition"
        while ($edition.count -ne 1) {
            $edition = Get-WindowsImage -ImagePath $ImagePath | Out-GridView -PassThru -Title "Select JUST ONE edition"
        }

        $VMSwitches = Get-VMSwitch
        $VMswitch = $VMSwitches | Out-GridView -PassThru -Title "Select the virtual switch for your VM"
        While ($VMswitch.count -ne 1) {
            $VMswitch = $VMSwitches | Out-GridView -PassThru -Title "Select JUST ONE virtual switch for your VM"
        }

        if(!(Test-Path -path $VMFolderPath)){
            # Create Path if doesn exist
            $NewPath = New-Item -Path $VMFolderPath -Force -ItemType Directory
        }

        $disk = Convert-Wim2VHD -Path $VMDiskPath -SourcePath $ISOPath -Dynamic -Size $Size -DiskLayout UEFI -Index $edition.ImageIndex

        $vm = New-VM -Name $VMName -VHDPath $VMDiskPath -Path $VMFolderPath -MemoryStartupBytes $Memory -Generation 2 -BootDevice VHD -SwitchName $VMswitch.Name

        $mount | Dismount-DiskImage

        return $vm
    }   


    catch {
        


    } 


} 