cd ./2.0.0/

if ! pgrep -f "app.py" > /dev/null; then
    nohup python3 app.py > /dev/null 2>&1 &
fi



