#!/bin/bash

# ==========================================================
# 1. CONFIGURATION
# ==========================================================

# Directory to mount the USB drive to
MOUNT_POINT="/media/usb"
# Directories from the vote signing tool (relative path)
INPUT_DIR="./input"
OUTPUT_DIR="./output"

# NOTE: The user must CONFIRM the correct device path for their USB drive.
# Common paths are /dev/sdb1, /dev/sdc1, etc.
USB_DEVICE_PATH="/dev/sdb1"
# ---------------------------------------------------------

# ==========================================================
# 2. ENVIRONMENT SETUP (AUTOMATED DIRECTORY CREATION)
# ==========================================================

echo "⚙️ Setting up USB mount directory: $MOUNT_POINT"
# The -p flag creates the directory only if it doesn't exist, and is silent if it does.
mkdir -p "$MOUNT_POINT"

# --- Function Definitions ---

# 1. Mount USB Drive
mount_usb_drive() {
    echo "--- 🔄 Attempting to Mount USB Drive ---"

    # Check if the drive is already mounted
    if mountpoint -q "$MOUNT_POINT"; then
        echo "⚠️ Drive is already mounted at $MOUNT_POINT."
        return 0
    fi

    echo "Mounting device $USB_DEVICE_PATH..."
    # Prompts for sudo password if necessary
    sudo mount "$USB_DEVICE_PATH" "$MOUNT_POINT" -o uid=$(id -u),gid=$(id -g)

    if [ $? -eq 0 ]; then
        echo "✅ USB Drive mounted successfully at $MOUNT_POINT."
        ls -lh "$MOUNT_POINT" # Show files on the drive for verification
    else
        echo "❌ MOUNT FAILED. Check if the USB is plugged in, or if the path ($USB_DEVICE_PATH) is correct."
    fi
}

# 2. Copy RAW Transaction File TO Signing Tool Input
copy_raw_to_input() {
    echo "--- ⬇️ Copying *.raw file from USB to $INPUT_DIR ---"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "❌ Drive is not mounted. Please run Menu 1 first."
        return 1
    fi

    # Find the *.raw file on the mounted USB drive
    RAW_FILE=$(find "$MOUNT_POINT" -maxdepth 1 -type f -name "*.raw" -print -quit)

    if [ -z "$RAW_FILE" ]; then
        echo "❌ No single *.raw file found on the USB drive."
    else
        # Copy the file
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

    # Find the *.signed file
    SIGNED_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.signed" -print -quit)

    if [ -z "$SIGNED_FILE" ]; then
        echo "❌ No single **.signed** file found in the $OUTPUT_DIR directory."
    else
        # Copy the file
        cp "$SIGNED_FILE" "$MOUNT_POINT/"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully copied **$(basename "$SIGNED_FILE")** to USB drive."
            ls -lh "$MOUNT_POINT"
        else
            echo "❌ Copy failed."
        fi
    fi
}

# 4. Unmount USB Drive
unmount_usb_drive() {
    echo "--- ⏏️ Attempting to Unmount USB Drive ---"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "⚠️ Drive is already unmounted or never mounted at $MOUNT_POINT."
        return 0
    fi

    # Unmount the drive. Using 'sudo' is often necessary.
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

PS3='Enter your choice (1-4): '
options=("Mount USB Drive" "Copy *.raw TO Input Folder" "Copy *.signed FROM Output Folder" "Unmount USB Drive" "Exit")

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
