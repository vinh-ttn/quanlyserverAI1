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

SERVERIP=$(ip -4 -br a | grep -v lo | grep -v docker | awk '{print $3}' | cut -d'/' -f1)
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
mkdir -p $BACKUP_DIR
chmod 0777 $BACKUP_DIR
MYSQL_USER="root"
MYSQL_PASSWORD="1234560123"
MYSQL_DUMP="/usr/bin/mysqldump"  # Adjust path if mysqldump is located elsewhere

# Function to perform MySQL backup
function backup_mysql() {
  local database_name="$1"
  local backup_file="$BACKUP_DIR/${database_name}_${CURRENT_TIME}.sql"

  # Create backup directory if it doesn't exist
  mkdir -p "$BACKUP_DIR"

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

  # Backup the database using sqlcmd
  $MSSQL_CMD -S $MSSQL_SERVER -U $MSSQL_USER -P $MSSQL_PASSWORD -Q "BACKUP DATABASE [$database_name] TO DISK = N'$backup_file'"

  if [ $? -eq 0 ]; then
    echoFormat "${CYAN}Da luu backup MSSQL '$database_name' tai: ${YELLOW}$backup_file${NC}"
  else
    echoFormat "${YELLOW}Khong the backup MSSQL database '$database_name'!${RED}"
  fi
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
##################
# MAIN PROGRAM
##################
gateway_path="$GAMEPATH/gateway"
gameserver_path="$GAMEPATH/server1"

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
    
             
elif [ "$arg1" == "help" ]; then
    if [ "$arg2" == "ip" ]; then
        usageInstruction "ip"
    else
        usageInstruction    
    fi
    
elif [ "$arg1" == "ip" ]; then
            
    if [ "$#" -eq 3 ]; then
        syncConfig "$arg2" "$arg3"
    elif [ "$#" -eq 2 ]; then
        syncConfig "$arge2" "$SERVERIP"
    else
        syncConfig "127.0.0.1" "$SERVERIP"
    fi
else
    if [ "$#" -ne 0 ]; then
        echoFormat "Khong hieu lenh 1: $arg1"
    fi
    usageInstruction
fi
