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

Run the script:
```powershell
.\Replace-NetworkAdapter.ps1


The script will prompt you to provide the vCenter credentials using the Get-Credential command.

Note: Ensure that you have the necessary permissions to perform the operations on the virtual machines.

Follow the on-screen instructions to specify the virtual machine(s) you want to replace the network adapter for.

The script will retrieve the network information, replace the network adapter, and reconfigure the network settings.

Review the output and any warnings or errors displayed during the execution of the script.

License
This project is licensed under the MIT License.

Contributing
Contributions are welcome! If you find any issues or want to add new features, please submit a pull request or open an issue.

Disclaimer
Use this script at your own risk. Ensure you have backups of your virtual machines before making any changes.
The script is provided as-is without any warranty or guarantee of its functionality.
Review the script and test it in a non-production environment before using it in a production environment.
