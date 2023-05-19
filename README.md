# VMware Network Adapter Replacement

This project provides a PowerShell script that allows you to replace the existing network adapter of a VMware virtual machine with a new one and reconfigure the network settings. The script leverages the VMware PowerCLI module and the vSphere API to perform the necessary operations.

## Features

- Retrieves network information for each NIC of a virtual machine, including IP addresses, interface indexes, and other network details.
- Retrieves static route information for a virtual machine.
- Replaces the existing network adapter with a new one (e.g., E1000 with VMXNET3) and reconfigures the network settings.
- Restores static routes with the correct adapter ID.

## Prerequisites

- VMware PowerCLI module must be installed. You can install it by running the following command:

  ```powershell
  Install-Module -Name VMware.PowerCLI -Scope CurrentUser



Sure! Here's a sample README document for your project:

sql
Copy code
# VMware Network Adapter Replacement

This project provides a PowerShell script that allows you to replace the existing network adapter of a VMware virtual machine with a new one and reconfigure the network settings. The script leverages the VMware PowerCLI module and the vSphere API to perform the necessary operations.

## Features

- Retrieves network information for each NIC of a virtual machine, including IP addresses, interface indexes, and other network details.
- Retrieves static route information for a virtual machine.
- Replaces the existing network adapter with a new one (e.g., E1000 with VMXNET3) and reconfigures the network settings.
- Restores static routes with the correct adapter ID.

## Prerequisites

- VMware PowerCLI module must be installed. You can install it by running the following command:

  ```powershell
  Install-Module -Name VMware.PowerCLI -Scope CurrentUser
Usage
Clone the repository or download the script files to your local machine.

Open a PowerShell console and navigate to the project directory.

Import the VMware PowerCLI module:
```powershell
Import-Module VMware.PowerCLI
