#!/bin/bash

# ==========================================================
# 1. GLOBAL CONFIGURATION
# ==========================================================

# >>> UPDATE THIS VARIABLE FOR EACH COMMITTEE MEMBER <<<
MEMBER="alice"
# -----------------------------------------------------

# Cold Machine Directories
INPUT_DIR="./input"
OUTPUT_DIR="./output"
KEY_DIR="./keys"

# Cardano CLI Path
CARDANO_CLI="/usr/local/bin/cardano-cli"

# USB Drive Configuration
MOUNT_POINT="/media/usb"
# NOTE: The user MUST CONFIRM the correct device path for their USB drive.
# Use 'lsblk' or 'fdisk -l' to determine this path.
USB_DEVICE_PATH="/dev/sdb1"

# Key Files (Tagged with MEMBER)
COLD_KEY="$KEY_DIR/${MEMBER}_hot.skey"
VKEY="$KEY_DIR/${MEMBER}_hot.vkey"
KEY_HASH="$KEY_DIR/${MEMBER}_hot_key.hash"

# ==========================================================
# 2. ENVIRONMENT SETUP
# ==========================================================

echo "⚙️ Setting up required directories..."
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR" "$KEY_DIR" "$INPUT_DIR/archive" "$MOUNT_POINT"

echo "Setup complete. Welcome, $MEMBER. Ready for operations."

# ==========================================================
# 3. USB MANAGEMENT FUNCTIONS
# ==========================================================

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
        ls -lh "$MOUNT_POINT"
    else
        echo "❌ MOUNT FAILED. Check if the USB is plugged in, or if the path ($USB_DEVICE_PATH) is correct."
        return 1
    fi
}

# 2. Copy RAW Transaction File TO Signing Tool Input Folder
copy_raw_to_input() {
    echo "--- ⬇️ Copying *.raw file from USB to $INPUT_DIR ---"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "❌ Drive is not mounted. Please Mount USB first."
        return 1
    fi

    RAW_FILE=$(find "$MOUNT_POINT" -maxdepth 1 -type f -name "*.raw" -print -quit)

    if [ -z "$RAW_FILE" ]; then
        echo "❌ No single *.raw file found on the USB drive."
        return 1
    else
        cp "$RAW_FILE" "$INPUT_DIR/"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully copied **$(basename "$RAW_FILE")** to $INPUT_DIR."
            ls -lh "$INPUT_DIR"
            return 0
        else
            echo "❌ Copy failed."
            return 1
        fi
    fi
}

# 3. Copy Signed Witness File FROM Signing Tool Output Folder
copy_witness_from_output() {
    echo "--- ⬆️ Copying *.witness file from $OUTPUT_DIR to USB ---"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "❌ Drive is not mounted. Please Mount USB first."
        return 1
    fi

    SIGNED_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.witness" -print -quit)

    if [ -z "$SIGNED_FILE" ]; then
        echo "❌ No single **.witness** file found in the $OUTPUT_DIR directory."
        return 1
    else
        cp "$SIGNED_FILE" "$MOUNT_POINT/"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully copied **$(basename "$SIGNED_FILE")** to USB drive."
            ls -lh "$MOUNT_POINT"
            return 0
        else
            echo "❌ Copy failed."
            return 1
        fi
    fi
}

# Transfer Key Hash to USB
transfer_hash_to_usb() {
    echo "--- ⬆️ Copying Key Hash file from $KEY_DIR to USB ---"

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "❌ Drive is not mounted. Please Mount USB first."
        return 1
    fi

    if [ ! -f "$KEY_HASH" ]; then
        echo "❌ Key Hash file ($KEY_HASH) not found. Run 'Get cc_hot Hash' (Menu 7) first."
        return 1
    fi

    cp "$KEY_HASH" "$MOUNT_POINT/"
    if [ $? -eq 0 ]; then
        echo "✅ Successfully copied **$(basename "$KEY_HASH")** to USB drive."
        ls -lh "$MOUNT_POINT"
        return 0
    else
        echo "❌ Copy failed."
        return 1
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
        return 1
    fi
}

# 6. Backup Keys to USB
backup_keys_to_usb() {
    echo "--- 🚨 KEY SECURITY WARNING 🚨 ---"
    echo "You are attempting to move sensitive keys. For use with a COLD USB ONLY"
    read -r -p "Do you wish to proceed with key backup? (Y/N): " CONFIRMATION

    if [[ "$CONFIRMATION" != "Y" && "$CONFIRMATION" != "y" ]]; then
        echo "❌ Backup aborted."
        return 0
    fi

    if ! mount_usb_drive; then
        echo "❌ Cannot proceed. Failed to mount USB drive."
        return 1
    fi

    USB_BACKUP_DIR="$MOUNT_POINT/cc_key_backup"
    mkdir -p "$USB_BACKUP_DIR"

    cp "$KEY_DIR"/*.skey "$USB_BACKUP_DIR/" 2>/dev/null
    cp "$KEY_DIR"/*.vkey "$USB_BACKUP_DIR/" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Key files copied successfully to $USB_BACKUP_DIR."
        ls -lh "$USB_BACKUP_DIR"
    else
        echo "❌ Key Backup FAILED. Check if key files exist in $KEY_DIR."
    fi

}


# ==========================================================
# 4. CARDANO CLI SIGNING FUNCTIONS
# ==========================================================

# 1. Generate Key Pair
generate_keys() {
    echo "--- 🔑 Generating cc_hot Key Pair for $MEMBER ---"
    if [ -f "$COLD_KEY" ]; then
        echo "⚠️ WARNING: cc_hot key already exists for $MEMBER at $COLD_KEY."
        return 1
    fi
    $CARDANO_CLI conway governance committee key-gen-hot --signing-key-file "$COLD_KEY" --verification-key-file "$VKEY"
    if [ $? -eq 0 ]; then
        echo "✅ Key Pair Generated Successfully!"
    else
        echo "❌ Key Generation FAILED. Check cardano-cli status."
        return 1
    fi
}

# 2. Get Key Hash
get_key_hash() {
    echo "--- 📋 Retrieving cc_hot Key Hash for $MEMBER ---"
    if [ ! -f "$VKEY" ]; then
        echo "❌ Verification Key ($VKEY) not found. Please run Key Generation (Menu 6) first."
        return 1
    fi
    $CARDANO_CLI conway governance committee key-hash --verification-key-file "$VKEY" > "$KEY_HASH"
    if [ $? -eq 0 ]; then
        echo "✅ Key Hash Retrieved Successfully!"
        echo "--------------------------------------------------------"
        echo "Key Hash: $(cat "$KEY_HASH")"
        echo "--------------------------------------------------------"
    else
        echo "❌ Hash Retrieval FAILED. Check cardano-cli status."
        return 1
    fi
}

# 3. Check for Unsigned File (*.raw) (Helper function)
check_unsigned_file() {
    UNSIGNED_FILES=($(find "$INPUT_DIR" -maxdepth 1 -type f -name "*.raw" | xargs -n 1 basename))
    if [ ${#UNSIGNED_FILES[@]} -eq 0 ]; then
        echo "❌ No unsigned vote file (*.raw) found in $INPUT_DIR."
        return 1
    elif [ ${#UNSIGNED_FILES[@]} -gt 1 ]; then
        echo "⚠️ WARNING: Multiple *.raw files found. Only one should be present."
        return 1
    else
        export UNSIGNED_FILE_NAME="${UNSIGNED_FILES[0]}"
        return 0
    fi
}

# 4. Sign the Vote File
sign_vote_file() {
    echo "--- ✍️ Signing Vote File with $MEMBER's Key ---"

    if [ ! -f "$COLD_KEY" ]; then
        echo "❌ Cold Signing Key ($COLD_KEY) not found. Please run Key Generation (Menu 6) first."
        return 1
    fi

    if ! check_unsigned_file; then
        echo "Cannot proceed with signing. Use Menu 2 to copy a file first."
        return
    fi

    UNSIGNED_PATH="$INPUT_DIR/$UNSIGNED_FILE_NAME"
    WITNESS_FILE_BASE=$(basename "$UNSIGNED_FILE_NAME" .raw)
    WITNESS_PATH="$OUTPUT_DIR/${MEMBER}_${WITNESS_FILE_BASE}.witness"

    echo "Attempting to sign $UNSIGNED_FILE_NAME..."

    $CARDANO_CLI conway transaction witness \
        --tx-body-file "$UNSIGNED_PATH" \
        --signing-key-file "$COLD_KEY" \
        --out-file "$WITNESS_PATH" \
        --testnet-magic 4

    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Signing Successful! Signed witness file created at: $WITNESS_PATH"
        mv "$UNSIGNED_PATH" "$INPUT_DIR/archive/" 2>/dev/null
        echo "Original raw file moved to archive."
    else
        echo "❌ SIGNING FAILED! Check the error messages above."
    fi
}


# ==========================================================
# 5. MAIN MENU LOGIC
# ==========================================================

PS3='Enter your choice (1-11): '
options=(
    "SYSTEM: Mount USB drive"
    "SYSTEM: Copy *.raw TO COLD machine"
    "VOTE: Sign Vote"
    "SYSTEM: Copy *.witness FROM COLD machine"
    "SYSTEM: Unmount USB"
    "ADMIN: Generate cc_hot Keys"
    "ADMIN: Get cc_hot Hash"
    "ADMIN: Transfer *.hash to USB"
    "ADMIN: Backup Keys to USB"
    "ADMIN: Shutdown Cold Machine"
    "ADMIN: Exit Menu"
)

echo "========================================================"
echo "--- 🗳️  Cardano CC COLD SIGNING WORKFLOW ---"
echo "Active User: **$MEMBER** | USB Device: **$USB_DEVICE_PATH**"
echo "========================================================"

select opt in "${options[@]}"
do
    case $opt in
        "SYSTEM: Mount USB drive")
            echo ""
            mount_usb_drive
            echo ""
            ;;
        "SYSTEM: Copy *.raw TO COLD machine")
            echo ""
            copy_raw_to_input
            echo ""
            ;;
        "VOTE: Sign Vote")
            echo ""
            sign_vote_file
            echo ""
            ;;
        "SYSTEM: Copy *.witness FROM COLD machine")
            echo ""
            copy_witness_from_output
            echo ""
            ;;
        "SYSTEM: Unmount USB")
            echo ""
            unmount_usb_drive
            echo ""
            ;;
        "ADMIN: Generate cc_hot Keys")
            echo ""
            generate_keys
            echo ""
            ;;
        "ADMIN: Get cc_hot Hash")
            echo ""
            get_key_hash
            echo ""
            ;;
        "ADMIN: Transfer *.hash to USB")
            echo ""
            transfer_hash_to_usb
            echo ""
            ;;
        "ADMIN: Backup Keys to USB")
            echo ""
            backup_keys_to_usb
            echo ""
            ;;
        "ADMIN: Shutdown Cold Machine")
            echo ""
            echo "🛑 Initiating system shutdown..."
            sudo shutdown -h now
            break
            ;;
        "ADMIN: Exit Menu")
            echo "Exiting CC Cold Signing Tool."
            break
            ;;
        *)
            echo "Invalid option $REPLY"
            ;;
    esac

    # This ensures the menu is always visible.
    # It prompts the user to read the output, then clears the screen
    # before the loop redraws the menu.
    if [[ "$opt" != "10. ADMIN: Shutdown Cold Machine" && "$opt" != "11. ADMIN: Exit Menu" ]]; then
        echo ""
        read -n 1 -s -r -p "Press any key to return to the menu..."
        clear
        # Also re-echo the header before the menu is drawn again by 'select'
        echo "========================================================"
        echo "--- 🗳️  Cardano CC COLD SIGNING WORKFLOW ---"
        echo "Active User: **$MEMBER** | USB Device: **$USB_DEVICE_PATH**"
        echo "========================================================"
    fi

done
