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
            "Hyper-ConvertImage"
        )

        $VMFolderPath = $VMsPath + $VMName
        $VMDiskPath = $VMFolderPath + "\Disk.VHDX"

        foreach ($m in $modules) {
            if (!(get-module "$m*" -ListAvailable)) {
                Write-Verbose "Installing $m module to currentUser.."
                Install-Module -Name $m -Scope CurrentUser -Force
                Import-Module -Name $m
            } else {
                Write-Verbose "$m module is already available!"
            }
        }

        $mount = Mount-DiskImage -ImagePath $isoPath -StorageType ISO -PassThru
        $driveLetter = ($mount | Get-Volume).DriveLetter
        $SourcePath  = "$($driveLetter):\sources\install.wim"

        Write-Verbose "Looking for $($SourcePath)..."
        if (!(Test-Path $SourcePath))
        {
            throw "The specified ISO does not appear to be valid Windows installation media."
        }
        $edition = Get-WindowsImage -ImagePath $SourcePath | Out-GridView -PassThru -Title "Select an edition"
        while ($edition.count -ne 1) {
            $edition = Get-WindowsImage -ImagePath $SourcePath | Out-GridView -PassThru -Title "Select JUST ONE edition"
        }

        $VMSwitches = Get-VMSwitch
        $VMswitch = $VMSwitches | Out-GridView -PassThru -Title "Select the virtual switch for your VM"
        While ($VMswitch.count -ne 1) {
            $VMswitch = $VMSwitches | Out-GridView -PassThru -Title "Select JUST ONE virtual switch for your VM"
        }

        # Create Path if it does not exist
        if(!(Test-Path -path $VMFolderPath)) {
            $NewPath = New-Item -Path $VMFolderPath -Force -ItemType Directory
        }

        $disk = Convert-WindowsImage -VhdPath $VMDiskPath -SourcePath $ISOPath -Dynamic -SizeBytes $Size -DiskLayout UEFI -Edition $edition.ImageIndex -Passthru

        $vm = New-VM -Name $VMName -VHDPath $VMDiskPath -Path $VMFolderPath -MemoryStartupBytes $Memory -Generation 2 -BootDevice VHD -SwitchName $VMswitch.Name

        $mount | Dismount-DiskImage

        return $vm
    }   

    catch {
        $errorMsg = $_
    } 

    finally {
        if ($errrorMsg) {
            Write-Warning $errorMsg
        }
    }


} 