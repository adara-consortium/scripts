# Adara Scripts
A small collection of guides and scripts with the hope of aiding operations for less-technical users.

## multisig.md
A markdown file outlining the potential steps for registering multisig cc_cold_script and cc_hot_script credentials. An alternative for those who find the learning curve of the Credential Manager tool too steep and in need of something more readily accessible.

## cc_suite_tool.sh
A bash script for less-technical command-line users wanting to control their own cc_hot voting keys. It produces a simple numbered menu combining all of the features previously provided by vote_signer_tool.sh and usb_tool.sh separately. Providing a complete workflow for mounting usb drives, transfering raw vote files, signing vote files, transferring witness files back to the usb drive, before unmounting the drive. Admin tools for creating cc_hot key pairs, generating hashes and backing up keys to additional cold storage devices are also included.

## vote_signer_tool.sh
A bash script for less-technical command-line users. It produces a simple numbered menu with commands to generate a cc_hot key pair, get the hash ready for a cc_hot_script, check for and sign vote files, and system shutdown.

## usb_tool.sh
A bash script for less-technical command-line users. It produces a simple numbered menu with commands to mount/unmount a usb drive, transfer files and backup keys.
