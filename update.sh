#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
APPPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
cd $APPPATH
echo "Dang chuan bi cap nhat...."
git reset --hard
git pull
echo "Da cap nhat xong app QuanLyServer den phien ban moi nhat. Co the dong cua so nay va chay lai app."
$APPPATH/start.sh
