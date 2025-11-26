#!/bin/bash

# ==========================================================
# 1. CONFIGURATION
# ==========================================================

# Directory to mount the USB drive to
MOUNT_POINT="/media/usb"
# Directories from the main vote signing tool (relative path)
INPUT_DIR="./input"
OUTPUT_DIR="./output"
KEY_DIR="./keys"

# NOTE: The user must CONFIRM the correct device path for their USB drive.
USB_DEVICE_PATH="/dev/sdb1"
# ---------------------------------------------------------

# ==========================================================
# 2. ENVIRONMENT SETUP (AUTOMATED DIRECTORY CREATION)
# ==========================================================

echo "⚙️ Setting up USB mount directory: $MOUNT_POINT"
# Create the mount point directory
mkdir -p "$MOUNT_POINT"

# --- Function Definitions ---

# 1. Mount USB Drive
mount_usb_drive() {
    echo "--- 🔄 Attempting to Mount USB Drive ---"

    if mountpoint -q "$MOUNT_POINT"; then
        echo "⚠️ Drive is already mounted at $MOUNT_POINT."
        return 0
    fi

    echo "Mounting device $USB_DEVICE_PATH..."
    sudo mount "$USB_DEVICE_PATH" "$MOUNT_POINT" -o uid=$(id -u),gid=$(id -g)

    if [ $? -eq 0 ]; then
        echo "✅ USB Drive mounted successfully at $MOUNT_POINT."
        ls -lh "$MOUNT_POINT" # Show files on the drive for verification
    else
        echo "❌ MOUNT FAILED. Check if the USB is plugged in, or if the path ($USB_DEVICE_PATH) is correct."
    fi
}

# 2. Copy RAW Transaction File TO Signing Tool Input Folder
copy_raw_to_input() {
    echo "--- ⬇️ Copying *.raw file from USB to $INPUT_DIR ---"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "❌ Drive is not mounted. Please run Menu 1 first."
        return 1
    fi

    RAW_FILE=$(find "$MOUNT_POINT" -maxdepth 1 -type f -name "*.raw" -print -quit)

    if [ -z "$RAW_FILE" ]; then
        echo "❌ No single *.raw file found on the USB drive."
    else
        cp "$RAW_FILE" "$INPUT_DIR/"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully copied **$(basename "$RAW_FILE")** to $INPUT_DIR."
            ls -lh "$INPUT_DIR"
        else
            echo "❌ Copy failed."
        fi
    fi
}

# 3. Copy Signed Witness File FROM Signing Tool Output
copy_witness_from_output() {
    echo "--- ⬆️ Copying *.signed file from $OUTPUT_DIR to USB ---"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "❌ Drive is not mounted. Please run Menu 1 first."
        return 1
    fi

    SIGNED_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.witness" -print -quit)

    if [ -z "$SIGNED_FILE" ]; then
        echo "❌ No single **.signed** file found in the $OUTPUT_DIR directory."
    else
        cp "$SIGNED_FILE" "$MOUNT_POINT/"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully copied **$(basename "$SIGNED_FILE")** to USB drive."
            ls -lh "$MOUNT_POINT"
        else
            echo "❌ Copy failed."
        fi
    fi
}

# 4. Backup Keys to USB (with Y/N verification)
backup_keys_to_usb() {
    echo "--- 🚨 KEY SECURITY WARNING 🚨 ---"
    echo "You are copying UNENCRYPTED private and public keys."
    echo "This USB drive **MUST** be treated as a **COLD BACKUP** - store it securely OFFLINE."
    echo "----------------------------------------------------"

    # Verification Prompt
    echo -n "Do you wish to proceed? (Y/N): "
    # The 'read -n 1' reads exactly one character, and the '|| read' allows input from non-interactive shell
    read -r -n 1 CONFIRMATION
    echo "" # Add a newline after the input

    # Check the user's input
    if [[ "$CONFIRMATION" != "Y" && "$CONFIRMATION" != "y" ]]; then
        echo "❌ Backup aborted. Returning to menu."
        return 0
    fi

    # --- Proceeding with Backup ---
    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "❌ Drive is not mounted. Please run Menu 1 first."
        return 1
    fi

    # Create a backup folder on the USB drive named after the KEY_DIR
    USB_BACKUP_DIR="$MOUNT_POINT/cc_key_backup"
    mkdir -p "$USB_BACKUP_DIR"

    # Copy all keys from the KEY_DIR to the USB backup folder
    cp "$KEY_DIR"/*.skey "$USB_BACKUP_DIR/" 2>/dev/null
    cp "$KEY_DIR"/*.vkey "$USB_BACKUP_DIR/" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Key files copied successfully to $USB_BACKUP_DIR."
        ls -lh "$USB_BACKUP_DIR"
        echo "Please verify the files and store this USB securely OFFLINE."
    else
        echo "❌ Key Backup FAILED. Check if key files exist in $KEY_DIR."
    fi
}


# 5. Unmount USB Drive
unmount_usb_drive() {
    echo "--- ⏏️ Attempting to Unmount USB Drive ---"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "⚠️ Drive is already unmounted or never mounted at $MOUNT_POINT."
        return 0
    fi

    sudo umount "$MOUNT_POINT"

    if [ $? -eq 0 ]; then
        echo "✅ USB Drive safely unmounted."
        echo "You can now safely remove the drive."
    else
        echo "❌ UNMOUNT FAILED. Files may be in use. Try closing all terminals and run again."
        echo "If persistent, use: **sudo umount -l $MOUNT_POINT** (Lazy unmount)."
    fi
}


# ==========================================================
# 3. MAIN MENU LOGIC
# ==========================================================

PS3='Enter your choice (1-6): '
# Note: Renumbering and reordering the options for logical flow
options=("Mount USB Drive" "Copy *.raw TO Input Folder" "Backup Keys to USB" "Copy *.signed FROM Output Folder" "Unmount USB Drive" "Exit")

echo "========================================================"
echo "--- 💻 Cold Machine USB Transfer Tool ---"
echo "========================================================"
echo "Device: **$USB_DEVICE_PATH** | Mount Point: **$MOUNT_POINT**"

select opt in "${options[@]}"
do
    case $opt in
        "Mount USB Drive")
            echo ""
            mount_usb_drive
            echo ""
            ;;
        "Copy *.raw TO Input Folder")
            echo ""
            copy_raw_to_input
            echo ""
            ;;
        "Backup Keys to USB")
            echo ""
            backup_keys_to_usb
            echo ""
            ;;
        "Copy *.signed FROM Output Folder")
            echo ""
            copy_witness_from_output
            echo ""
            ;;
        "Unmount USB Drive")
            echo ""
            unmount_usb_drive
            echo ""
            ;;
        "Exit")
            echo "Exiting USB tool."
            break
            ;;
        *)
            echo "Invalid option $REPLY"
            ;;
    esac
done
