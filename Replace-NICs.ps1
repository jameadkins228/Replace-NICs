# Prompt user for vCenter credentials
if(!($vcCredentials)) { ($vcCredentials = Get-Credential)}

function Get-NICData {
    <#
    .SYNOPSIS
    Retrieves network information for each NIC of a virtual machine.

    .DESCRIPTION
    This function retrieves information for each NIC (Network Interface Card) of a virtual machine, including IP addresses, interface indexes, and other network details.

    .PARAMETER VirtualMachines
    The virtual machines for which to retrieve NIC data.

    .EXAMPLE
    Get-NICData -VirtualMachines (Get-VM "VMName")
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, 
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = 'List of virtual machine objects to process. Must be a Windows guest.',
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [array]$VirtualMachines
    )

    foreach ($vm in $VirtualMachines) {
        $vmData = [PSCustomObject]@{
            GuestName      = $vm.Guest.HostName
            IPAddressInfo  = @()
            StaticRoutes   = @()
            DefaultGateway = $null
            Subnet         = $null
            NICType        = $null
            MACAddress     = $null
            vDS            = $null
            VLANID         = $null
            InterfaceName  = $null
            OS             = $vm.Guest.OsFullname
        }

        try {
            $networkAdapters = Get-NetworkAdapter -VM $vm
            $cardData = Get-CimInstance -ComputerName $vm.Guest.HostName -ClassName win32_networkadapterconfiguration -Filter 'ipenabled = "true"'

            foreach ($adapter in $networkAdapters) {
                $ipAddressInfo = [PSCustomObject]@{
                    IPAddress      = $null
                    SkipAsSource   = $null
                    InterfaceIndex = $null
                }

                $matchingCard = $cardData | Where-Object { $_.MACAddress -eq $adapter.MacAddress }

                if ($matchingCard) {
                    $ipAddressInfo.IPAddress = $matchingCard.IPAddress
                    $ipAddressInfo.SkipAsSource = $matchingCard.SkipAsSource
                    $ipAddressInfo.InterfaceIndex = $matchingCard.InterfaceIndex
                }

                $vmData.IPAddressInfo += $ipAddressInfo
            }

            $vmData.StaticRoutes = Get-StaticRoutes -VirtualMachine $vm

            $cardData | ForEach-Object {
                $macAddress = $_.MACAddress
                $ifIndex = $_.InterfaceIndex

                $vmData.DefaultGateway = $_.DefaultIPGateway
                $vmData.Subnet = $_.IPSubnet
                $vmData.NICType = $networkAdapters | Where-Object { $_.MacAddress -eq $macAddress } | Select-Object -ExpandProperty Type
                $vmData.MACAddress = $macAddress
                $vmData.vDS = Get-VDSwitch -VM $vm
                $vmData.VLANID = $networkAdapters | Where-Object { $_.MacAddress -eq $macAddress } | Select-Object -ExpandProperty NetworkName
                $vmData.InterfaceName = $networkAdapters | Where-Object { $_.MacAddress -eq $macAddress }
            }
        }
        catch {
            Write-Warning "Failed to retrieve NIC data for VM '$($vm.Name)': $_"
        }

        $vmData
    }
}

function Get-StaticRoutes {
    <#
    .SYNOPSIS
    Retrieves static route information for a virtual machine.

    .DESCRIPTION
    This function retrieves the static route information for the specified virtual machine.

    .PARAMETER VirtualMachine
    The virtual machine for which to retrieve static route information.

    .EXAMPLE
    Get-StaticRoutes -VirtualMachine $vm
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, 
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = 'The virtual machine for which to retrieve static route information.',
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$VirtualMachine
    )
    
    $routes = @()

    try {
        $routeList = Invoke-Command -Credential $vcCredentials -ComputerName $VirtualMachine.Guest.HostName -ScriptBlock {
            Get-NetAdapter | Get-NetRoute -AddressFamily IPv4 | Where-Object {
                $_.Nexthop -notlike "0.0.0.0" -and $_.DestinationPrefix -notlike "0.0.0.0/0"
            }
        }

        $routes += $routeList
    }
    catch {
        Write-Warning "Failed to retrieve static routes for VM '$($VirtualMachine.Name)': $_"
    }

    $routes
}

function Replace-NetworkAdapter {
    <#
    .SYNOPSIS
    Replaces the existing network adapter with a new one and reconfigures the network settings.

    .DESCRIPTION
    This function replaces the existing network adapter of a virtual machine with a new one (e.g., E1000 with VMXNET3). It also reconfigures the network settings using the gathered information.

    .PARAMETER VirtualMachine
    The virtual machine object for which to replace the network adapter.

    .EXAMPLE
    $vm = Get-VM "MyVM"
    Replace-NetworkAdapter -VirtualMachine $vm
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = 'The virtual machine object for which to replace the network adapter.',
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$VirtualMachine
    )

    try {
        # Check if the existing adapter is E1000
        $existingAdapter = $VirtualMachine.ExtensionData.Config.Hardware.Device | Where-Object {
            $_.DeviceInfo.Label -eq 'Network adapter 1' -and $_.GetType().Name -eq 'VirtualE1000'
        }

        if ($existingAdapter) {
            $networkAdapter = Get-NetworkAdapter -VM $VirtualMachine | Where-Object { $_.MacAddress -eq $existingAdapter.MacAddress }

            # Remove the existing E1000 adapter
            $networkAdapter | Remove-NetworkAdapter -Confirm:$false

            # Add a new VMXNET3 adapter
            $newAdapter = New-NetworkAdapter -VM $VirtualMachine -Type Vmxnet3 -StartConnected -Confirm:$false

            # Update network settings using gathered information
            $newAdapter.IpAddress = $networkAdapter.IPAddressInfo.IPAddress
            $newAdapter.SubnetMask = $networkAdapter.Subnet
            $newAdapter.MacAddress = $networkAdapter.MacAddress

            Set-NetworkAdapter -NetworkAdapter $newAdapter -Confirm:$false

            # Restore static routes with correct adapter ID
            $staticRoutes = $networkAdapter.StaticRoutes
            $newAdapterId = (Get-NetworkAdapter -VM $VirtualMachine | Where-Object { $_.MacAddress -eq $newAdapter.MacAddress }).Id

            foreach ($route in $staticRoutes) {
                $nextHop = $route.NextHop
                $destination = $route.DestinationPrefix
                $interfaceIndex = $newAdapterId

                Invoke-Command -Credential $vcCredentials -ComputerName $VirtualMachine.Guest.HostName -ScriptBlock {
                    $adapter = Get-NetAdapter | Where-Object { $_.InterfaceIndex -eq $using:interfaceIndex }
                    if ($adapter) {
                        New-NetRoute -DestinationPrefix $using:destination -InterfaceIndex $adapter.InterfaceIndex -NextHop $using:nextHop -Confirm:$false
                    }
                }
            }
        }
        else {
            Write-Host "No E1000 adapter found for VM '$($VirtualMachine.Name)'. Skipping replacement."
        }
    }
    catch {
        Write-Warning "Failed to replace network adapter for VM '$($VirtualMachine.Name)': $_"
    }
}

# Example usage
$vm = Get-VM "MyVM"
$nicData = Get-NICData -VirtualMachines $vm
foreach ($vmData in $nicData) {
    Replace-NetworkAdapter -VirtualMachine $vm
}
