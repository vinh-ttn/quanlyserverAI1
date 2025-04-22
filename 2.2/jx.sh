#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
APPPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'
: "${GAMEPATH:=/home/jxser}"

# Get server IP and MAC from environment or auto-detect
# Check if we have received SERVER_IP and SERVER_MAC from the environment
if [ -n "$SERVER_IP" ]; then
    SERVERIP="$SERVER_IP"
else
    # Auto-detect if not provided
    SERVERIP=$(ip -4 -br a | grep -v 'lo\|docker' | awk '{print $3}' | cut -d'/' -f1)
fi

if [ -n "$SERVER_MAC" ]; then
    SERVERMAC="$SERVER_MAC"
else
    # Auto-detect if not provided
    SERVERINTERFACE=$(ip -4 -br a | grep -v 'lo\|docker' | awk '{print $1}')
    SERVERMAC=$(cat /sys/class/net/$SERVERINTERFACE/address | sed 's/:/-/g')
    SERVERMAC="${SERVERMAC^^}"
fi

usageInstruction(){

    if [ "$1" != "ip" ]; then
        echoFormat "${YELLOW}IP: ${SERVERIP}${NC} (nen kiem tra bang lenh ${CYAN}ip -4 -br a${NC})"
        echoFormat ""
        echoFormat "${YELLOW}JX Linux Tool${NC}"
        echoFormat "  jx ${CYAN}(start | stop | clean | backup)${NC}: dieu khien server"
        echoFormat "  jx ${CYAN}(start | stop) (bishop | s3relay | gameserver)${NC}: chay tung phan server (dev)"
        echoFormat "  jx ${CYAN}ip (<PaysysIP>) (<GameServerIP>)${NC}: cai dat IP cua PaysysWin va GameServer vao file config"

    else

        echoFormat "${YELLOW}GameServer IP: ${SERVERIP}${NC}"
    fi
    exit 1
}


# Assign arguments to variables for better readability
arg1=$1
arg2=$2
arg3=$3

# HELPERS
echoFormat(){
    echo -e "$1"
}
sleepAbit(){
    N=$1

    for (( i=0; i<N; i++ )); do
      echoFormat "."
      sleep 1
    done
}

# MAIN PROGRAM
cleanUpLog(){
    echoFormat "Bat dau xoa log file va core dump"
    find $GAMEPATH/server1 -type f -name "core*" -exec rm -f {} \;
    find $GAMEPATH/gateway/s3relay -type f -name "core*" -exec rm -f {} \;
    rm -rf $GAMEPATH/server1/Logs/*
    rm -rf $GAMEPATH/gateway/Logs/*
    rm -rf $GAMEPATH/gateway/s3relay/Logs/*
    rm -rf $GAMEPATH/gateway/s3relay/RelayRunData/*
    chmod -R 0777 $GAMEPATH
    echoFormat "Da don dep xong server"
}

syncConfig(){
    cd $APPPATH
    echoFormat $(php serverconfig.php $1 $2 $GAMEPATH)

    cat $GAMEPATH/server1/servercfg.ini > $GAMEPATH/server1/servercf0.ini
    TARGET="$GAMEPATH/server1/server_start"
    SYMLINK="$GAMEPATH/server1/jx_linux_y"
    if ! [ -e "$SYMLINK" ]; then
      ln -s "$TARGET" "$SYMLINK"
    fi
}


goddess_start(){
    if ! pgrep -f "goddess_y" > /dev/null; then
        echoFormat "Dang khoi dong goddess_y"
        cd $GAMEPATH/gateway
        xfce4-terminal --title=Goddess --tab --working-directory="$GAMEPATH/gateway" --command "./goddess_y"
        sleepAbit 3
        echoFormat "Da chay xong goddess_y"
    else
        echoFormat "Da co goddess_y dang chay"
    fi
}
goddess_stop(){
    echoFormat "Dang tat goddess_y"
    pkill -f './goddess_y'
    sleepAbit 2
    echoFormat "Da tat xong goddess_y"
}

bishop_start(){


    if ! pgrep -f "bishop_y" > /dev/null; then
        echoFormat "Da khoi dong bishop_y"
        cd $GAMEPATH/gateway
        xfce4-terminal --title=Bishop --tab --working-directory="$GAMEPATH/gateway" --command "./bishop_y"
        sleepAbit 5
        echoFormat "Da chay xong bishop_y"
    else
        echoFormat "Da co bishop_y dang chay"
    fi
}
bishop_stop(){
    echoFormat "Dang tat bishop_y"
    pkill -f './bishop_y'
    sleepAbit 2
    echoFormat "Da tat xong bishop_y"
}

s3relay_start(){
    if ! pgrep -f "s3relay_y" > /dev/null; then
        cd $GAMEPATH/gateway/s3relay
        echoFormat "Dang chay s3relay_y"
        xfce4-terminal --title=S3Relay  --tab --working-directory="$GAMEPATH/gateway/s3relay" --command "./s3relay_y"
        sleepAbit 5
        echoFormat "Da chay xong s3relay_y"
    else
        echoFormat "Da co s3 relay_y dang chay"
    fi
}

s3relay_stop(){
    pkill -f './s3relay_y'
    echoFormat "Da tat s3relay_y"
}


gameserver_start(){
    if ! pgrep -f "jx_linux_y" > /dev/null; then
        cd $GAMEPATH/server1
        xfce4-terminal --title=server1 --tab --working-directory="$GAMEPATH/server1" --command "./jx_linux_y"
        echoFormat "Dang chay jx_linux_y"
    else
        echoFormat "Da co jx_linux_y dang chay"
    fi
}

gameserver_stop(){
    pkill -f './s3relay_y'
    echoFormat "Dang cho gameserver luu du lieu nhan vat"
    while pgrep -f './jx_linux_y' > /dev/null; do
        sleepAbit 1
    done
    echoFormat "Da tat game server"
}


paysys_start(){
    cleanUpLog
    syncConfig "127.0.0.1" "$SERVERIP"
    updateAddress "account_tong" "$SERVERIP"
    if ! pgrep -f "Sword3PaySys.exe" > /dev/null; then
        echoFormat "Dang khoi dong Sword3PaySys.exe"
        /root/serversetup/paysyswin/startPaysys.sh
        sleepAbit 3
        echoFormat "Da chay xong Sword3PaySys.exe"
    else
        echoFormat "Da co Sword3PaySys.exe dang chay"
    fi
}
paysys_stop(){
    echoFormat "Dang tat Sword3PaySys.exe"
    /root/serversetup/paysyswin/stopPaysys.sh
    sleepAbit 2
    echoFormat "Da tat xong Sword3PaySys.exe"
}


relayserver_start(){

    if ! pgrep -f "S3RelayServer.exe" > /dev/null; then
        echoFormat "Dang khoi dong S3RelayServer.exe"
        /root/serversetup/paysyswin/startS3RelayServer.sh
        sleepAbit 3
        echoFormat "Da chay xong S3RelayServer.exe"
    else
        echoFormat "Da co S3RelayServer.exe dang chaycd "
    fi
}
relayserver_stop(){
    echoFormat "Dang tat S3RelayServer.exe"
    /root/serversetup/paysyswin/stopS3RelayServer.sh
    sleepAbit 2
    echoFormat "Da tat xong S3RelayServer.exe"
}

full_stop(){
    gameserver_stop
    bishop_stop
    goddess_stop
    paysys_stop
    relayserver_stop
    echoFormat "Da tat toan bo"
}

full_start(){
    paysys_start
    relayserver_start
    sleepAbit 10
    goddess_start
    bishop_start
    sleepAbit 2
    s3relay_start
    sleepAbit 3
    gameserver_start
}

#########################
# DATABSE BACKUP FEATURE
#########################

# Set directory format for backups
CURRENT_TIME=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/home/database_backups"
MYSQL_USER="root"
MYSQL_PASSWORD="1234560123"
MYSQL_DUMP="/usr/bin/mysqldump"  # Adjust path if mysqldump is located elsewhere

# Function to perform MySQL backup
function backup_mysql() {
  local database_name="$1"
  local backup_file="$BACKUP_DIR/${database_name}_${CURRENT_TIME}.sql"

  # Create backup directory if it doesn't exist
  mkdir -p "$BACKUP_DIR"
  chmod 0777 $BACKUP_DIR
  # Dump the database to the specified file
  $MYSQL_DUMP -u $MYSQL_USER -p$MYSQL_PASSWORD -h 127.0.0.1 "$database_name" > "$backup_file"

  if [ $? -eq 0 ]; then
    echoFormat "${CYAN}Da luu backup MySQL '$database_name' tai: ${YELLOW}$backup_file${NC}"
  else
    echoFormat "${YELLOW}Khong the backup MySQL database '$database_name'!${RED}"
  fi
}

# MSSQL server details (replace with your actual configuration)
MSSQL_SERVER="127.0.0.1"
MSSQL_USER="SA"
MSSQL_PASSWORD="SAJx123456"
MSSQL_DATABASE="account_tong"
MSSQL_CMD="/opt/mssql-tools/bin/sqlcmd"  # Adjust path if sqlcmd is located elsewhere

# Function to perform MSSQL backup
function backup_mssql() {
  local database_name="$1"
  local backup_file="$BACKUP_DIR/${database_name}_${CURRENT_TIME}.bak"

  # Create backup directory if it doesn't exist
  mkdir -p "$BACKUP_DIR"
  chmod 0777 "$BACKUP_DIR"

  # Backup the database using sqlcmd
  $MSSQL_CMD -S $MSSQL_SERVER -U $MSSQL_USER -P $MSSQL_PASSWORD -Q "BACKUP DATABASE [$database_name] TO DISK = N'$backup_file'"

  if [ $? -eq 0 ]; then
    echoFormat "${CYAN}Da luu backup MSSQL '$database_name' tai: ${YELLOW}$backup_file${NC}"
  else
    echoFormat "${YELLOW}Khong the backup MSSQL database '$database_name'!${RED}"
  fi
}

function updateAddress(){
  local database_name="$1"
  local gameIP="$2"
  $MSSQL_CMD -S $MSSQL_SERVER -U $MSSQL_USER -P $MSSQL_PASSWORD -d $database_name -Q "UPDATE ServerList set cIP='$gameIP', cMemo='$SERVERMAC' WHERE iid=1;"
}


backup(){
    echoFormat "Bat dau backup db"

    # Get database names (replace with your logic to list databases)
    mysql_databases="server1"  # Replace with actual database names
    mssql_databases="account_tong"  # Replace with actual database names

    # Backup MySQL databases
    for database in $mysql_databases; do
      backup_mysql "$database"
    done

    # Backup MSSQL databases
    for database in $mssql_databases; do
      backup_mssql "$database"
    done

    thunar $BACKUP_DIR

}

raise_error() {
    echoFormat "Loi: $1"
    exit 1
}
patch_server(){
    
    
    # Show menu options
    echo -e "\nLua chon cach cap nhat:"
    echo "[1] Cai dat/cap nhat SimCity moi nhat"
    echo "[2] Download cac gameserver tu github vinh-ttn/jx1-gs"
    echo "[3] Download cac gameserver tu github khac"
    echo "[4] Cai dat/cap nhat (github khac)"
    echo -e "\nVui long chon mot lua chon (1-4):"
    read option_choice

    # Validate user choice
    if ! [[ "$option_choice" =~ ^[1-4]$ ]]; then
        echoFormat "Lua chon khong hop le"
        return 1
    fi

    # For options 1 and 4, confirm server stop
    if [ "$option_choice" == "1" ] || [ "$option_choice" == "4" ]; then
        echoFormat "Ban dang cap nhat ${CYAN}${GAMEPATH}${NC}"
        while true; do
            read -p "Vui long xac nhan dung server [co/khong]?  " user_input
            if [ "$user_input" != "co" ]; then
                echoFormat "Ket thuc cap nhat. Ban co the dong cua so nay."
                return 1
            else
                break
            fi
        done
    fi

    # Handle different options
    case $option_choice in
        1)  # Cai dat simcity
            target="vinh-ttn/simcity"
            branch="main"
            ;;
        2)  # Download gameserver (vinh-ttn/jx1-gs)
            # Download and process using the new gameserver download logic
            INDEX_URL="https://raw.githubusercontent.com/vinh-ttn/jx1-gs/refs/heads/main/index.txt"
            RAW_CONTENT_URL="https://raw.githubusercontent.com/vinh-ttn/jx1-gs/refs/heads/main"
            
            # Download and parse index.txt
            echo "Dang tai danh sach tap tin..."
            index_content=$(wget -qO- "$INDEX_URL")
            if [ $? -ne 0 ]; then
                echoFormat "Loi: Khong the tai danh sach tap tin"
                return 1
            fi

            # Find all entries containing jxser.tar.gz
            declare -a available_paths
            while IFS= read -r line; do
                if [[ "$line" == *"jxser.tar.gz"* ]]; then
                    folder_path=$(dirname "$line")
                    available_paths+=("$folder_path")
                fi
            done <<< "$index_content"

            if [ ${#available_paths[@]} -eq 0 ]; then
                echoFormat "Loi: Khong tim thay tap tin jxser.tar.gz trong danh sach"
                return 1
            fi

            while true; do
                # List available folders
                echo -e "\nCac thu muc co san:"
                for i in "${!available_paths[@]}"; do
                    echo "[$i] ${available_paths[$i]}"
                done
                
                # Ask user to choose folder
                echo -e "\nVui long chon mot thu muc (nhap so):"
                read choice
                
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -lt ${#available_paths[@]} ]; then
                    chosen_path="${available_paths[$choice]}"
                    break
                else
                    echoFormat "Loi: Lua chon khong hop le"
                fi
            done

            # Ask for target extraction folder
            while true; do
                echo -e "\nNhap ten thu muc de giai nen vao (khong duoc de trong):"
                read target_folder
                
                if [ -z "$target_folder" ]; then
                    echo "Loi: Ten thu muc khong duoc de trong"
                    continue
                fi

                # Check if folder exists
                if [ -d "/home/${target_folder}" ]; then
                    echo "Loi: Thu muc '/home/$target_folder' da ton tai. Vui long chon ten khac"
                    continue
                fi
                
                break
            done

            # Download and extract
            source_url="$RAW_CONTENT_URL/${chosen_path}/jxser.tar.gz"
            echo -e "\nDang tai tap tin tu $source_url..."
            
            # Create temporary directory
            temp_dir=$(mktemp -d)
            temp_file="$temp_dir/jxser.tar.gz"
            extract_dir="$temp_dir/extract"
            mkdir -p "$extract_dir"

            if ! wget -q "$source_url" -O "$temp_file"; then
                echoFormat "Loi: Khong the tai tap tin"
                rm -rf "$temp_dir"
                return 1
            fi

            echo "Dang giai nen tap tin..."
            if ! tar -xzf "$temp_file" -C "$extract_dir"; then
                echoFormat "Loi: Khong the giai nen tap tin"
                rm -rf "$temp_dir"
                return 1
            fi

            # Check for required folders
            if ! { [ -d "$extract_dir/server1" ] && [ -d "$extract_dir/gateway" ]; } && \
               ! { [ -d "$extract_dir/jxser/server1" ] && [ -d "$extract_dir/jxser/gateway" ]; }; then
                echoFormat "Loi: Khong tim thay thu muc server1 va gateway trong tap tin"
                rm -rf "$temp_dir"
                return 1
            fi

            # Create target directory
            mkdir -p "/home/${target_folder}"

            # Copy files to target directory
            if [ -d "$extract_dir/server1" ] && [ -d "$extract_dir/gateway" ]; then
                cp -rfp "$extract_dir/server1" "$extract_dir/gateway" "/home/${target_folder}/"
            elif [ -d "$extract_dir/jxser/server1" ] && [ -d "$extract_dir/jxser/gateway" ]; then
                cp -rfp "$extract_dir/jxser/server1" "$extract_dir/jxser/gateway" "/home/${target_folder}/"
            fi

            chmod -R 0777 "/home/${target_folder}/server1"
            chmod -R 0777 "/home/${target_folder}/gateway"

            # Cleanup
            rm -rf "$temp_dir"
            echoFormat "Da cap nhat game server xong"
            return 0
            ;;
        3)  # Download gameserver (khac)
            while true; do
                read -p "Nhap dia chi Github [v.d. username/repo]?  " user_input
                if [[ $user_input =~ ^[^/]+/[^/]+$ ]]; then
                    INDEX_URL="https://raw.githubusercontent.com/$user_input/refs/heads/main/index.txt"
                    RAW_CONTENT_URL="https://raw.githubusercontent.com/$user_input/refs/heads/main"
                    break
                else
                    echoFormat "Sai dinh dang github. Can nhap theo dang username/repo"
                fi
            done
            
            # Reuse the same download and extract logic as option 2
            # Download and parse index.txt
            echo "Dang tai danh sach tap tin..."
            index_content=$(wget -qO- "$INDEX_URL")
            if [ $? -ne 0 ]; then
                echoFormat "Loi: Khong the tai danh sach tap tin"
                return 1
            fi

            # Find all entries containing jxser.tar.gz
            declare -a available_paths
            while IFS= read -r line; do
                if [[ "$line" == *"jxser.tar.gz"* ]]; then
                    folder_path=$(dirname "$line")
                    available_paths+=("$folder_path")
                fi
            done <<< "$index_content"

            if [ ${#available_paths[@]} -eq 0 ]; then
                echoFormat "Loi: Khong tim thay tap tin jxser.tar.gz trong danh sach"
                return 1
            fi

            while true; do
                # List available folders
                echo -e "\nCac thu muc co san:"
                for i in "${!available_paths[@]}"; do
                    echo "[$i] ${available_paths[$i]}"
                done
                
                # Ask user to choose folder
                echo -e "\nVui long chon mot thu muc (nhap so):"
                read choice
                
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -lt ${#available_paths[@]} ]; then
                    chosen_path="${available_paths[$choice]}"
                    break
                else
                    echoFormat "Loi: Lua chon khong hop le"
                fi
            done

            # Ask for target extraction folder
            while true; do
                echo -e "\nNhap ten thu muc de giai nen vao (khong duoc de trong):"
                read target_folder
                
                if [ -z "$target_folder" ]; then
                    echo "Loi: Ten thu muc khong duoc de trong"
                    continue
                fi

                # Check if folder exists
                if [ -d "/home/${target_folder}" ]; then
                    echo "Loi: Thu muc '/home/$target_folder' da ton tai. Vui long chon ten khac"
                    continue
                fi
                
                break
            done

            # Download and extract
            source_url="$RAW_CONTENT_URL/${chosen_path}/jxser.tar.gz"
            echo -e "\nDang tai tap tin tu $source_url..."
            
            # Create temporary directory
            temp_dir=$(mktemp -d)
            temp_file="$temp_dir/jxser.tar.gz"
            extract_dir="$temp_dir/extract"
            mkdir -p "$extract_dir"

            if ! wget -q "$source_url" -O "$temp_file"; then
                echoFormat "Loi: Khong the tai tap tin"
                rm -rf "$temp_dir"
                return 1
            fi

            echo "Dang giai nen tap tin..."
            if ! tar -xzf "$temp_file" -C "$extract_dir"; then
                echoFormat "Loi: Khong the giai nen tap tin"
                rm -rf "$temp_dir"
                return 1
            fi

            # Check for required folders
            if ! { [ -d "$extract_dir/server1" ] && [ -d "$extract_dir/gateway" ]; } && \
               ! { [ -d "$extract_dir/jxser/server1" ] && [ -d "$extract_dir/jxser/gateway" ]; }; then
                echoFormat "Loi: Khong tim thay thu muc server1 va gateway trong tap tin"
                rm -rf "$temp_dir"
                return 1
            fi

            # Create target directory
            mkdir -p "/home/${target_folder}"

            # Copy files to target directory
            if [ -d "$extract_dir/server1" ] && [ -d "$extract_dir/gateway" ]; then
                cp -rfp "$extract_dir/server1" "$extract_dir/gateway" "/home/${target_folder}/"
            elif [ -d "$extract_dir/jxser/server1" ] && [ -d "$extract_dir/jxser/gateway" ]; then
                cp -rfp "$extract_dir/jxser/server1" "$extract_dir/jxser/gateway" "/home/${target_folder}/"
            fi

            chmod -R 0777 "/home/${target_folder}/server1"
            chmod -R 0777 "/home/${target_folder}/gateway"

            # Cleanup
            rm -rf "$temp_dir"
            echoFormat "Da cap nhat game server xong"
            return 0
            ;;
        4)  # Cai dat khac
            while true; do
                # Prompt user for target and optional branch
                read -p "Dia chi Github de cap nhat [v.d. vinh-ttn/simcity]?  " user_input

                # Validate the input format
                if [[ $user_input =~ ^[^,]+(,[^,]+)?$ ]]; then
                    # Extract target and branch from the input
                    if [[ $user_input =~ , ]]; then
                        target=$(echo $user_input | cut -d',' -f1)
                        branch=$(echo $user_input | cut -d',' -f2)
                    else
                        target=$user_input
                        branch="main"
                    fi
                    break
                else
                    echo "Sai dinh dang github."
                fi
            done
            ;;
    esac

    # For options 1 and 4, handle simcity and other installations
    if [ "$option_choice" == "1" ] || [ "$option_choice" == "4" ]; then
        # For vinh-ttn/simcity repository, backup existing simcity directory
        if [[ "$target" == "vinh-ttn/simcity" ]]; then
            SIMCITY_DIR="${GAMEPATH}/server1/script/global/vinh/simcity"
            BACKUP_PARENT_DIR="${GAMEPATH}/server1/script/global/vinh"
            
            # Check if directory exists
            if [ -d "$SIMCITY_DIR" ]; then
                BACKUP_DATE=$(date +%Y-%m-%d_%H-%M-%S)
                BACKUP_FILE="${BACKUP_PARENT_DIR}/simcity_backup_${BACKUP_DATE}.tar.gz"
                
                echoFormat "Dang sao luu thu muc simcity hien tai..."
                # Create backup tar.gz with date in filename
                tar -czf "$BACKUP_FILE" -C "$BACKUP_PARENT_DIR" simcity
                
                if [ $? -eq 0 ]; then
                    echoFormat "${GREEN}Da sao luu simcity vao: $BACKUP_FILE${NC}"
                    
                    # Remove existing directory
                    echoFormat "Dang xoa thu muc simcity hien tai..."
                    rm -rf "$SIMCITY_DIR"
                    echoFormat "${GREEN}Da xoa thu muc simcity hien tai${NC}"
                else
                    echoFormat "${RED}Loi khi sao luu simcity. Tien trinh cap nhat bi huy.${NC}"
                    return 1
                fi
            else
                echoFormat "${YELLOW}Khong tim thay thu muc simcity, se tao moi.${NC}"
            fi
        fi

        # Generate the GitHub link
        github_link="https://github.com/$target/archive/refs/heads/$branch.tar.gz"

        # Download the .tar.gz file
        temp_dir=$(mktemp -d)
        temp_tar="$temp_dir/archive.tar.gz"
        wget -O "$temp_tar" "$github_link" || raise_error "Khong tim thay file $github_link de download."

        # Extract the .tar.gz file to a temporary directory
        temp_extract_dir=$(mktemp -d)
        tar -xzvf "$temp_tar" -C "$temp_extract_dir" || raise_error "Khong the giai nen file da download."

        server1_path=$(find "$temp_extract_dir" -type d -name "server1" | head -n 1)
        gateway_path=$(find "$temp_extract_dir" -type d -name "gateway" | head -n 1)

        # Check if server1 folder exists in the extracted files
        if [ -d "$server1_path" ]; then
            chmod -R 0777 "$server1_path/"
            cp -rfp "$server1_path/." "$GAMEPATH/server1/"
        fi

        if [ -d "$gateway_path" ]; then
            chmod -R 0777 "$gateway_path/"
            cp -rfp "$gateway_path/." "$GAMEPATH/gateway/"
        fi

        # Cleanup temporary files
        rm -rf "$temp_dir"
        rm -rf "$temp_extract_dir"
    fi

    echoFormat "Da cap nhat game server xong. Ban co the dong cua so nay. (Ctrl Shift W)"
}
##################
# MAIN PROGRAM
##################
gateway_path="$GAMEPATH/gateway"
gameserver_path="$GAMEPATH/server1"

# Debug output
echoFormat "Server IP: $SERVERIP"
echoFormat "Server MAC: $SERVERMAC"
echoFormat "Gateway: $gateway_path"
echoFormat "GameServer: $gameserver_path"


# Perform actions based on the values of arg1 and arg2
if [ "$arg1" == "start" ]; then

    if ! [ -d "$gateway_path" ]; then
        echo "Khong tim thay thu muc game '$gateway_path'. Vui long kiem tra lai cai dat trong app"
        exit 0  # Exit with success (0) since a directory exists
    fi

    if ! [ -d "$gameserver_path" ]; then
        echo "Khong tim thay thu muc game '$gameserver_path'. Vui long kiem tra lai cai dat trong app"
        exit 0  # Exit with success (0) since a directory exists
    fi


    if [ "$arg2" == "goddess" ]; then
        goddess_start
    elif [ "$arg2" == "bishop" ]; then
        bishop_start
    elif [ "$arg2" == "s3relay" ]; then
        s3relay_start
    elif [ "$arg2" == "jx_linux" ]; then
        gameserver_start
    elif [ "$arg2" == "PaySys" ]; then
        paysys_start
    elif [ "$arg2" == "RelayServer" ]; then
        relayserver_start
    elif [ "$arg2" == "clean" ]; then
        cleanUpLog
    elif [ -z "$2" ]; then
        full_start
    else
        echoFormat "Khong hieu lenh 2: $arg2"
    fi
elif [ "$arg1" == "stop" ]; then

    if [ "$arg2" == "goddess" ]; then
        goddess_stop
    elif [ "$arg2" == "bishop" ]; then
        bishop_stop
    elif [ "$arg2" == "s3relay" ]; then
        s3relay_stop
    elif [ "$arg2" == "jx_linux" ]; then
        gameserver_stop
    elif [ "$arg2" == "PaySys" ]; then
        paysys_stop
    elif [ "$arg2" == "RelayServer" ]; then
        relayserver_stop
    elif [ "$arg2" == "clean" ]; then
        cleanUpLog
    elif [ -z "$2" ]; then
        full_stop
    else
        echoFormat "Khong hieu lenh 2: $arg2"
    fi


elif [ "$arg1" == "backup" ]; then
    backup



elif [ "$arg1" == "patch" ]; then
    if ! [ -d "$gateway_path" ]; then
        echo "Khong tim thay thu muc game '$gateway_path'. Vui long kiem tra lai cai dat trong app"
        exit 0  # Exit with success (0) since a directory exists
    fi

    if ! [ -d "$gameserver_path" ]; then
        echo "Khong tim thay thu muc game '$gameserver_path'. Vui long kiem tra lai cai dat trong app"
        exit 0  # Exit with success (0) since a directory exists
    fi


    patch_server

elif [ "$arg1" == "help" ]; then
    if [ "$arg2" == "ip" ]; then
        usageInstruction "ip"
    else
        usageInstruction
    fi

elif [ "$arg1" == "ip" ]; then

    if [ "$#" -eq 3 ]; then
        syncConfig "$arg2" "$arg3"
        updateAddress "account_tong" "$arg3"

    elif [ "$#" -eq 2 ]; then
        syncConfig "$arge2" "$SERVERIP"
        updateAddress "account_tong" "$SERVERIP"
    else
        syncConfig "127.0.0.1" "$SERVERIP"
        updateAddress "account_tong" "$SERVERIP"
    fi
else
    if [ "$#" -ne 0 ]; then
        echoFormat "Khong hieu lenh 1: $arg1"
    fi
    usageInstruction
fi
