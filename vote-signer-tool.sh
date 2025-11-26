#!/bin/bash

# ==========================================================
# 1. CONFIGURATION
# ==========================================================
# >>> UPDATE THIS VARIABLE FOR EACH COMMITTEE MEMBER <<<
MEMBER="Member1"
# -----------------------------------------------------

INPUT_DIR="./input"
OUTPUT_DIR="./output"
KEY_DIR="./keys"

# Key files are tagged with the MEMBER variable
COLD_KEY="$KEY_DIR/${MEMBER}_cold.skey"
VKEY="$KEY_DIR/${MEMBER}_cold.vkey"
KEY_HASH="$KEY_DIR/${MEMBER}_hot_key.hash"
CARDANO_CLI="/usr/local/bin/cardano-cli"

# ==========================================================
# 2. ENVIRONMENT SETUP (AUTOMATED DIRECTORY CREATION)
# ==========================================================

echo "⚙️ Setting up required directories..."
# -p flag ensures the directories are created only if they don't exist,
# and it suppresses warnings if they already do.
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR" "$KEY_DIR" "$INPUT_DIR/archive"

echo "Setup complete. Welcome, $MEMBER."

# --- Function Definitions ---

# 1. Generate Key Pair
generate_keys() {
    echo "--- 🔑 Generating Cold Key Pair for $MEMBER ---"

    if [ -f "$COLD_KEY" ]; then
        echo "⚠️ WARNING: Cold key already exists for $MEMBER at $COLD_KEY."
        echo "To regenerate, you must manually delete the existing key files first!"
        return 1
    fi

    # Generate the Cold Signing Key
    echo "Generating Signing Key ($COLD_KEY)..."
    # cardano-cli command
    $CARDANO_CLI conway governance committee key-gen-hot --signing-key-file "$COLD_KEY" --verification-key-file "$VKEY"

    # Check for successful generation
    if [ $? -eq 0 ]; then
        echo "✅ Key Pair Generated Successfully!"
        echo "Signing Key saved to: $COLD_KEY"
        echo "Verification Key saved to: $VKEY"
        echo "NOTE: This is an UNENCRYPTED key pair."
    else
        echo "❌ Key Generation FAILED. Check cardano-cli status."
        return 1
    fi
}

# 2. Get Key Hash
get_key_hash() {
    echo "--- 📋 Retrieving Key Hash for $MEMBER ---"

    if [ ! -f "$VKEY" ]; then
        echo "❌ Verification Key ($VKEY) not found. Please run Key Generation (Menu 1) first."
        return 1
    fi

    # Get the Verification Key Hash
    echo "Calculating hash for $VKEY..."
    # cardano-cli command
    $CARDANO_CLI conway governance committee key-hash --verification-key-file "$VKEY" > "$KEY_HASH"

    # Display the result to the user
    if [ $? -eq 0 ]; then
        echo "✅ Key Hash Retrieved Successfully!"
        echo "--------------------------------------------------------"
        echo "Key Hash (for on-chain registration for $MEMBER):"
        echo $(cat "$KEY_HASH")
        echo "--------------------------------------------------------"
    else
        echo "❌ Hash Retrieval FAILED. Check cardano-cli status."
        return 1
    fi
}

# 3. Check for Unsigned File (*.raw)
check_unsigned_file() {
    echo "--- 🔍 Checking Input Directory ---"
    # Find only *.raw files in the input directory
    UNSIGNED_FILES=($(find "$INPUT_DIR" -maxdepth 1 -type f -name "*.raw" | xargs -n 1 basename))

    if [ ${#UNSIGNED_FILES[@]} -eq 0 ]; then
        echo "❌ No unsigned vote file (*.raw) found in $INPUT_DIR."
        return 1
    elif [ ${#UNSIGNED_FILES[@]} -gt 1 ]; then
        echo "⚠️ WARNING: Multiple *.raw files found. Please ensure only ONE unsigned file is in $INPUT_DIR."
        printf "Found files: %s\n" "${UNSIGNED_FILES[@]}"
        return 1
    else
        echo "✅ Found unsigned file: ${UNSIGNED_FILES[0]}"
        export UNSIGNED_FILE_NAME="${UNSIGNED_FILES[0]}"
        return 0
    fi
}

# 4. Sign the Vote File
sign_vote_file() {
    echo "--- ✍️ Signing Vote File with $MEMBER's Key ---"

    if [ ! -f "$COLD_KEY" ]; then
        echo "❌ Cold Signing Key ($COLD_KEY) not found. Please run Key Generation (Menu 1) first."
        return 1
    fi

    if ! check_unsigned_file; then
        echo "Cannot proceed with signing. Please check the input directory."
        return
    fi

    UNSIGNED_PATH="$INPUT_DIR/$UNSIGNED_FILE_NAME"
    WITNESS_FILE_BASE=$(basename "$UNSIGNED_FILE_NAME" .raw)
    # The signed output file is prefixed with the MEMBER variable
    WITNESS_PATH="$OUTPUT_DIR/${MEMBER}_${WITNESS_FILE_BASE}.witness"

    echo "Attempting to sign $UNSIGNED_FILE_NAME..."

    # Sign the witness transaction
    $CARDANO_CLI conway transaction witness \
        --tx-body-file "$UNSIGNED_PATH" \
        --signing-key-file "$COLD_KEY" \
        --out-file "$WITNESS_PATH" \
        --testnet-magic 4 # Or other network parameter

    # Check the exit status of the last command
    if [ $? -eq 0 ]; then
        echo ""
        echo "--------------------------------------------------------"
        echo "🎉 Signing Successful! Signed file saved to:"
        echo "$WITNESS_PATH"
        echo "--------------------------------------------------------"
        # Move the raw file to an archive/signed folder to prevent re-signing
        mv "$UNSIGNED_PATH" "$INPUT_DIR/archive/" 2>/dev/null
        echo "Original raw file moved to archive."
    else
        echo ""
        echo "--------------------------------------------------------"
        echo "❌ SIGNING FAILED! Check the error messages above."
        echo "--------------------------------------------------------"
    fi
}


# ==========================================================
# 3. MAIN MENU LOGIC
# ==========================================================
PS3='Enter your choice (1-6): '
options=("Generate Cold Keys" "Get Cold Key Hash" "Check for Unsigned File (*.raw)" "Sign the Vote File" "Shutdown Cold Machine" "Exit Menu")

echo "========================================================"
echo "--- 🗳️ Cardano CC Key & Signing Tool (Bash) ---"
echo "Active User: **$MEMBER**"
echo "========================================================"
echo "NOTE: Ensure physical security; keys are stored unencrypted."

select opt in "${options[@]}"
do
    case $opt in
        "Generate Cold Keys")
            echo ""
            generate_keys
            echo ""
            ;;
        "Get Cold Key Hash")
            echo ""
            get_key_hash
            echo ""
            ;;
        "Check for Unsigned File (*.raw)")
            echo ""
            check_unsigned_file
            echo ""
            ;;
        "Sign the Vote File")
            echo ""
            sign_vote_file
            echo ""
            ;;
        "Shutdown Cold Machine")
            echo ""
            echo "🛑 Initiating system shutdown..."
            sudo shutdown -h now
            break
            ;;
        "Exit Menu")
            echo "Exiting signing menu."
            break
            ;;
        *)
            echo "Invalid option $REPLY"
            ;;
    esac
done
