#!/bin/bash

# Server Backup and Restore Script with Vietnamese prompts
# This script handles SSH connections, tar creation, and file transfers
# with proper support for Chinese characters and other non-ASCII filenames

set -e  # Exit on error

# ANSI color codes
RED='\033[0;33m'
GREEN='\033[0;33m'
YELLOW='\033[0;33m'
BLUE='\033[0;33m'
NC='\033[0m' # No Color

# -------------------------------------------------------
# MESSAGE DEFINITIONS - Modify these for language changes
# -------------------------------------------------------
MSG_TITLE="JX1 GAME SERVER COPY"
MSG_DESCRIPTION="Huong dan su dung:\n    1. Dung de copy Game Server tu may khac nhu CentOS6.5, CentOS7 (cac bo game nhu pgaming, pyta82, hoiquan v.v.) ve may 1ClickVMFull nay.\n    2. Yeu cau may do co the ket noi duoc tu may 1ClickVMFull nay.\n    3. Hay thu ping tu may nay den IP do truoc khi su dung cong cu nay de kiem tra.\n    4. Neu day la lan dau tien su dung cong cung nay co the phai doi 1 lat de cap nhat 1ClickVMFull truoc khi co the copy.)"
MSG_ENTER_IP="Nhap dia chi IP (may khac): "
MSG_PINGING="Dang kiem tra ket noi toi may chu..."
MSG_PING_FAILED="Khong the ket noi toi may chu. Vui long kiem tra IP va thu lai."
MSG_RETRY_IP="Ban co muon nhap dia chi IP khac khong? (c/k): "
MSG_ENTER_USERNAME="Username (v.d. root): "
MSG_ENTER_PASSWORD="Password (v.d. 123456, pgaming): "
MSG_TESTING_CONNECTION="Dang kiem tra ket noi SSH..."
MSG_CONNECTION_SUCCESS="Ket noi thanh cong!"
MSG_CONNECTION_FAILED="Khong the ket noi den may chu. Vui long kiem tra thong tin dang nhap va thu lai."
MSG_ENTER_REMOTE_FOLDER="Nhap duong dan Game Server can copy (v.d. /home/jxser): "
MSG_FOLDER_NOT_EXIST="Thu muc da chi dinh khong ton tai tren may chu."
MSG_RETRY_FOLDER="Ban co muon nhap duong dan khac khong? (c/k): "
MSG_CANCELING="..."
MSG_EXIT="Ban co the dong cua so nay (Ctrl Shift W)"
MSG_CREATING_TAR="Dang tao tap tin nen tren may chu..."
MSG_TAR_TIME_WARNING="Qua trinh nay co the mat mot thoi gian tuy thuoc vao kich thuoc thu muc..."
MSG_TAR_FAILED="Khong the tao tap tin nen tren may chu."
MSG_TAR_SUCCESS="Tap tin nen da duoc tao thanh cong tren may chu!"
MSG_DOWNLOADING="Dang tai xuong tap tin nen ve may 1ClickVM..."
MSG_DOWNLOAD_FAILED="Khong the tai xuong tap tin nen tu may chu."
MSG_DOWNLOAD_SUCCESS="Tap tin nen da duoc tai xuong thanh cong tai: "
MSG_CLEANING_TEMP="Da xoa tap tin tam thoi tren may chu."
MSG_CLEANING_LOCAL_TAR="Da xoa tap tin nen cuc bo sau khi giai nen."
MSG_EXTRACTING="Dang giai nen tap tin..."
MSG_EXTRACT_FAILED="Khong the giai nen tap tin."
MSG_EXTRACT_SUCCESS="Da copy thanh cong tai: "
MSG_PROCESS_COMPLETE="Qua trinh copy Game Server da hoan tat thanh cong!"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

exitWithMessage(){
    print_message $YELLOW "$MSG_EXIT"
    exit 1
}

# Output directory configuration
LOCAL_DOWNLOAD_DIR="/home/downloads"
mkdir -p "$LOCAL_DOWNLOAD_DIR"

print_message $BLUE "========================================"
print_message $YELLOW "$MSG_TITLE"
print_message $BLUE "========================================"
print_message $NC "$MSG_DESCRIPTION"
print_message $BLUE "========================================"

# Step 1: Collect server information and check connectivity
while true; do
    read -p "$MSG_ENTER_IP" SERVER_IP
    
    # Check if server is pingable
    print_message $YELLOW "$MSG_PINGING"
    if ping -c 2 -W 5 "$SERVER_IP" &> /dev/null; then
        print_message $GREEN "$MSG_CONNECTION_SUCCESS"
        break
    else
        print_message $RED "$MSG_PING_FAILED"
        read -p "$MSG_RETRY_IP" TRY_AGAIN
        if [[ "${TRY_AGAIN,,}" != "c" ]]; then
            print_message $YELLOW "$MSG_CANCELING"
            exitWithMessage
        fi
    fi
done

# After verifying ping, ask for credentials
read -p "$MSG_ENTER_USERNAME" USERNAME
read -s -p "$MSG_ENTER_PASSWORD" PASSWORD
echo

# Generate a timestamp for the backup file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Function to run SSH commands with password
run_ssh() {
    local command="$1"
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$USERNAME@$SERVER_IP" "$command"
}

# Function to run SCP commands with password
run_scp() {
    local src="$1"
    local dest="$2"
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no "$src" "$dest"
}

# Step 2: Install sshpass if not already installed
if ! command -v sshpass &> /dev/null; then
    print_message $YELLOW "Cài đặt sshpass..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y sshpass
    elif command -v brew &> /dev/null; then
        brew install hudochenkov/sshpass/sshpass
    else
        print_message $RED "Không thể cài đặt sshpass. Vui lòng cài đặt thủ công."
        exitWithMessage
    fi
fi

# Step 3: Test SSH connection
print_message $YELLOW "$MSG_TESTING_CONNECTION"

# Test connection with password
if ! run_ssh "echo '$MSG_CONNECTION_SUCCESS'" &> /dev/null; then
    print_message $RED "$MSG_CONNECTION_FAILED"
    exitWithMessage
fi

print_message $GREEN "$MSG_CONNECTION_SUCCESS"

# Step 4: Ask for folder path on remote server
while true; do
    read -p "$MSG_ENTER_REMOTE_FOLDER" REMOTE_FOLDER

    # Check if folder exists on remote server
    if run_ssh "[ -d \"$REMOTE_FOLDER\" ] && echo 'exists'" | grep -q "exists"; then
        break  # Exit the loop if directory exists
    else
        print_message $RED "$MSG_FOLDER_NOT_EXIST"
        read -p "$MSG_RETRY_FOLDER" TRY_AGAIN
        if [[ "${TRY_AGAIN,,}" != "c" ]]; then
            print_message $YELLOW "$MSG_CANCELING"
            exitWithMessage
        fi
    fi
done

# Extract folder name for naming the tar file
FOLDER_NAME=$(basename "$REMOTE_FOLDER")
TAR_FILENAME="${FOLDER_NAME}_${TIMESTAMP}.tar"
REMOTE_TAR_PATH="/tmp/$TAR_FILENAME"

# Step 5: Create tar file on remote server
print_message $YELLOW "$MSG_CREATING_TAR"
print_message $YELLOW "$MSG_TAR_TIME_WARNING"

# Create the tar file on the remote server - simplified approach
PARENT_DIR=$(dirname "$REMOTE_FOLDER")
BASE_NAME=$(basename "$REMOTE_FOLDER")

# Use simpler commands with less complex quoting
if ! run_ssh "cd $PARENT_DIR && tar -cf $REMOTE_TAR_PATH $BASE_NAME && chmod 644 $REMOTE_TAR_PATH && echo success" | grep -q "success"; then
    print_message $RED "$MSG_TAR_FAILED"
    # Show directory listing for debugging
    run_ssh "ls -la $PARENT_DIR"
    exitWithMessage
fi

print_message $GREEN "$MSG_TAR_SUCCESS"

# Step 6: Download tar file to local machine
print_message $YELLOW "$MSG_DOWNLOADING"

# Set the local tar path in the configured download directory
LOCAL_TAR_PATH="$LOCAL_DOWNLOAD_DIR/$TAR_FILENAME"

if ! run_scp "$USERNAME@$SERVER_IP:$REMOTE_TAR_PATH" "$LOCAL_TAR_PATH"; then
    print_message $RED "$MSG_DOWNLOAD_FAILED"
    exitWithMessage
fi

print_message $GREEN "$MSG_DOWNLOAD_SUCCESS$LOCAL_TAR_PATH"

# Clean up remote tar file
run_ssh "rm -f \"$REMOTE_TAR_PATH\" && echo 'cleaned'" > /dev/null
print_message $YELLOW "$MSG_CLEANING_TEMP"

# Define the extraction directory
EXTRACT_PATH="$LOCAL_DOWNLOAD_DIR"
mkdir -p "$EXTRACT_PATH"

# Extract the tar file
print_message $YELLOW "$MSG_EXTRACTING"
if ! tar -xf "$LOCAL_TAR_PATH" -C "$EXTRACT_PATH"; then
    print_message $RED "$MSG_EXTRACT_FAILED"
    exitWithMessage
fi

# Clean up the local tar file after extraction
rm -f "$LOCAL_TAR_PATH"
print_message $YELLOW "$MSG_CLEANING_LOCAL_TAR"

print_message $BLUE "========================================"
print_message $YELLOW "$MSG_EXTRACT_SUCCESS"
print_message $BLUE "========================================"
print_message $NC "$EXTRACT_PATH"
print_message $BLUE "========================================"

print_message $BLUE "$MSG_PROCESS_COMPLETE"
print_message $YELLOW "$MSG_EXIT"
