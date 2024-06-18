#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
APPPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"

chmod -r 0755 "$APPPATH/*"
cd ./2.0.0/

if ! pgrep -f "app.py" > /dev/null; then
    nohup python3 app.py > /dev/null 2>&1 &
fi



