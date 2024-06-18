import tkinter as tk
from tkinter import messagebox
from tkinter import ttk
import time
import subprocess
import json
import socket
import os
from tkinter import filedialog

# Get the absolute path of the current script
current_script_path = os.path.abspath(__file__)

# Get the directory name of the current script
APP_DIR_FULL = os.path.dirname(current_script_path)
APP_DIR_NAME = os.path.basename(APP_DIR_FULL)

BASH_SCRIPT = os.path.join(APP_DIR_FULL, "jx.sh")
# Check if the script is executable
def is_executable(file_path):
    return os.path.isfile(file_path) and os.access(file_path, os.X_OK)

# Make the script executable
def make_executable(file_path):
    mode = os.stat(file_path).st_mode
    mode |= stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
    os.chmod(file_path, mode)

# Ensure the script is executable
if not is_executable(BASH_SCRIPT):
    make_executable(BASH_SCRIPT)

 

CONFIGFILE = 'app.json'
TRANSLATION = {
    "app_title": "Quản lý server",
    "app_version": APP_DIR_NAME,
    "status_off": "đã tắt",
    "status_on": "đang chạy",

    "button_on": "Mở",
    "button_off": "Tắt",
    "button_backup": "Backup",
    "button_log": "log",
    "button_start_all": "Mở tất cả",
    "button_stop_all": "Tắt tất cả",
    "button_users": "Tài khoản",
    "button_changeServer": "Đổi server",
    "autostart": "boot"
}

def now():
    return int(time.time())


def save_dict_to_file(dict_obj, filename):
    with open(filename, 'w') as file:
        json.dump(dict_obj, file)

def load_dict_from_file(filename):
    try:
        with open(filename, 'r') as file:
            return json.load(file)
    except FileNotFoundError:
        return {} 

def getLANIP():

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(0)
    s.connect(('8.8.8.8', 1))  # connect() for UDP doesn't send packets
    ip_address = s.getsockname()[0]
    s.close()
    return ip_address

class ProcessDashboard(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title(TRANSLATION["app_title"] + " " + TRANSLATION["app_version"] + " - vinhttn")
        self.geometry("400x680")
        self.resizable(False, True)  # Make the window not resizable

        # Set the background color of the main window
        self.configure(bg='#ffffff')
        self.protocol("WM_DELETE_WINDOW", self.on_closing)

        menuColor = "#e5f3ff"

        # Apply a theme
        style = ttk.Style(self)
        style.theme_use('clam')  # You can change to 'alt', 'clam', 'default', etc.
        
        style.configure("TLabel", background="#ffffff", foreground="#333", borderwidth=0, font=("Helvetica", 10,"italic"))
        style.configure("IP.TLabel", background="#ffffff", foreground="#1f73b7", font=("Helvetica", 16,"bold"), borderwidth=0)
        style.configure("GS.TLabel", background="#ffffff", foreground="#000", font=("Helvetica", 12,"normal"), borderwidth=0)
        style.configure("Author.TLabel", background="#ffffff", foreground="#555", font=("Helvetica", 8,"normal"), borderwidth=0)        
        style.configure("PName.TLabel", background="#ececec", foreground="#000", font=("Helvetica", 10,"bold"), borderwidth=0)
        style.configure("StatusOn.TLabel", background="#ececec", foreground="#1db24a", font=("Helvetica", 10,"normal"), borderwidth=0)
        style.configure("StatusOff.TLabel", background="#ececec", foreground="#f50707", font=("Helvetica", 10,"normal"), borderwidth=0)
        style.configure("ChangeServer.TLabel", background="#ffffff", foreground="#000", font=("Helvetica", 10,"bold"), borderwidth=0)
        style.configure("SectionHeader.TLabel", background=menuColor, foreground="#1f73b7", font=("Helvetica", 16,"bold"), borderwidth=0)


        style.configure("TCheckbutton", background="#ffffff", foreground="#333", borderwidth=0)
        style.configure("TFrame", background="#ffffff", borderwidth=0)

        style.configure("SectionHeader.TFrame", background=menuColor, borderwidth=0)
        
        style.configure("MainController.TFrame", background="#ffffff", borderwidth=0)
        style.configure("ProcessesList.TFrame", background="#ececec", borderwidth=0)
        style.configure("HiddenProcessesList.TFrame", background="#fff", borderwidth=0)
        style.configure("ChangeServer.TFrame", background="#ffffff", borderwidth=0) 

        style.configure("Start.TButton", width=5, background="#1f73b7", foreground="#ffffff", borderwidth=1, relief="solid", bordercolor="#1f73b7")
        style.configure("Stop.TButton", width=3, background="#ffffff", foreground="#1f73b7", borderwidth=1, relief="solid", bordercolor="#1f73b7")
        style.configure("StopAll.TButton", width=10, background="#cc3340", foreground="#ffffff", borderwidth=1, relief="solid", bordercolor="#cc3340")
        style.configure("StartAll.TButton", width=10, background="#1f73b7", foreground="#ffffff", borderwidth=1, relief="solid", bordercolor="#1f73b7")
        style.configure("Backup.TButton", width=7, background="#ffffff", foreground="#1f73b7", borderwidth=0, relief="solid", bordercolor="#1f73b7")
        style.configure("Users.TButton", width=10, background="#ffffff", foreground="#1f73b7", borderwidth=1, relief="solid", bordercolor="#1f73b7")
        style.configure("Log.TButton", width=3, background="#ffffff", foreground="#1f73b7", borderwidth=0, relief="solid", bordercolor="#1f73b7")
        style.configure("UpdateApp.TButton", width=12, background="#ffffff", foreground="#1f73b7", borderwidth=1, relief="solid", bordercolor="#1f73b7")
 
        style.map("Start.TButton", background=[('active', '#144A75')])
        style.map("Stop.TButton", bordercolor=[('active', '#1F73B7')])
        style.map("StartAll.TButton", background=[('active', '#144A75')])
        style.map("StopAll.TButton", bordercolor=[('active', '#68232c')], background=[('active', '#68232c')])        
        style.map("Log.TButton", bordercolor=[('active', '#1F73B7')])
 
        # Load JSON config
        self.CONFIG = load_dict_from_file(CONFIGFILE)

        # Local var for the app
        self.processes = {
            "PaySys": { "status": False },
            "RelayServer": { "status": False },
            "goddess_y": { "status": False },
            "bishop_y": { "status": False },
            "s3relay_y": { "status": False },
            "jx_linux_y": { "status": False }
        }
        self.hidden_processes = {
            "MySQL": { "status": False },
            "MSSQL": { "status": False }
        }
        
        self.UI = {} 
 
        # Render section on screen
        #self.UI_render_appIP(0)
        self.UI_render_mainHeader(1)
        self.UI_render_mainController(2)
        self.UI_render_appProcesses(3)
        
        self.UI_render_systemHeader(4)
        self.UI_render_changeServer(5)
        self.UI_render_hiddenAppProcesses(6)        
        #self.UI_render_authorInfo(7)

        # Adjust the sections
        for i in range(1,6):
            self.grid_rowconfigure(i, weight=0)
        self.grid_rowconfigure(6, weight=1)
        self.grid_columnconfigure(0, weight=1) 

        # Periodically check process
        self._monitoring()  # Start the process checking loop
 
    def UI_render_mainHeader(self, row):
        table_frame = ttk.Frame(self, padding="15", style="SectionHeader.TFrame")
        table_frame.grid(row=row, column=0, sticky="nsew")

        # Create a frame for the table1
        ipText = ttk.Label(table_frame, text="Server "+getLANIP(), style="SectionHeader.TLabel")
        ipText.pack(side='left', padx=(0,5))


    def UI_render_systemHeader(self, row):
        table_frame = ttk.Frame(self, padding="15", style="SectionHeader.TFrame")
        table_frame.grid(row=row, column=0, sticky="nsew")

        # Create a frame for the table1
        ipText = ttk.Label(table_frame, text="Công cụ khác", style="SectionHeader.TLabel")
        ipText.pack(side='left', padx=(0,5))


        
    def UI_render_appIP(self,row):
        table_frame = ttk.Frame(self, padding="0 10", style="TFrame")
        table_frame.grid(row=row, column=0, sticky="nsew")

        # Create a frame for the table1
        ipText = ttk.Label(table_frame, text="IP: "+getLANIP(), style="IP.TLabel")
        ipText.grid(row=0, column=0, sticky='ew', padx=15, pady=(20,10))


    def UI_render_changeServer(self,row):


        main_frame = ttk.Frame(self, padding="15 15", style="ChangeServer.TFrame")
        main_frame.grid(row=row, column=0, sticky="nsew")

        table_frame = ttk.Frame(main_frame, padding="0", style="ChangeServer.TFrame")
        table_frame.grid(row=0, column=0, sticky="nsew")

        #Line 1: server path
        directoryText = ttk.Label(table_frame, text="Server path: "+self.CONFIG["directory"], style="ChangeServer.TLabel")
        directoryText.grid(row=0, column=0, sticky="e")

        btn_frame = ttk.Frame(table_frame)
        btn_frame.grid(row=0, column=1, sticky='e', padx=12, pady=5) 
        changeServer_button = ttk.Button(btn_frame, text=TRANSLATION["button_changeServer"], command=lambda : self.onBtnClick("mainMenu", "changeDir_btn"), style="Backup.TButton", width=12)
        changeServer_button.pack(side='left', padx=2)
        
        self.UI_register("mainMenu", "changeDir_btn", changeServer_button)
        self.UI_register("mainMenu", "changeDir_label", directoryText)

        #Line 2: app

        directoryText = ttk.Label(table_frame, text="Phiên bản: "+APP_DIR_NAME, style="ChangeServer.TLabel")
        directoryText.grid(row=1, column=0, sticky="nsew")

        btn_frame = ttk.Frame(table_frame)
        btn_frame.grid(row=1, column=1, sticky='nsew', padx=12, pady=5) 
 
        start_btn = ttk.Button(btn_frame, text="Cập nhật app", command=lambda : self.onBtnClick("mainMenu", "updateApp"), style="Backup.TButton", width=12)
        start_btn.pack(side='left', padx=2)
    


    def UI_render_hiddenAppProcesses(self,row):
        # Create a frame for the table2

        
        table_frame = ttk.Frame(self, padding="10 0", style="HiddenProcessesList.TFrame")
        table_frame.grid(row=row, column=0, padx=(0,10), sticky="nsew")
        
        currentRow = 0
        ttk.Label(table_frame, text="MSSQL", style="PName.TLabel",  background="#fff").grid(row=currentRow, column=0, sticky='w', padx=5, pady=5)
        status_label = ttk.Label(table_frame, text=TRANSLATION["status_off"], style="StatusOff.TLabel",  background="#fff")
        status_label.grid(row=currentRow, column=1, sticky='w', padx=12, pady=5)        
        self.UI_register("MSSQL", "status_label", status_label)



        btn_frame = ttk.Frame(table_frame)
        btn_frame.grid(row=currentRow, column=2, sticky='e', padx=12, pady=5) 

        backup_button = ttk.Button(btn_frame, text=TRANSLATION["button_backup"], command=lambda : self.onBtnClick("mainMenu", "backup_btn"), style="Backup.TButton")
        backup_button.pack(side='left', padx=2)
        self.UI_register("mainMenu", "backup_btn", backup_button)

        currentRow = currentRow + 1

        ttk.Label(table_frame, text="MySQL", style="PName.TLabel",  background="#fff").grid(row=currentRow, column=0, sticky='w', padx=5, pady=5)
        status_label = ttk.Label(table_frame, text=TRANSLATION["status_off"], style="StatusOff.TLabel",  background="#fff")
        status_label.grid(row=currentRow, column=1, sticky='w', padx=12, pady=5)        
        self.UI_register("MySQL", "status_label", status_label)
     

        btn_frame = ttk.Frame(table_frame)
        btn_frame.grid(row=currentRow, column=2, sticky='e', padx=12, pady=5)  

        start_btn = ttk.Button(btn_frame, text=TRANSLATION["button_on"], command=lambda :  self.onBtnClick("mainMenu", "startDB_btn"), style="Backup.TButton")
        start_btn.pack(side='left', padx=2)

        self.UI_register("mainMenu", "startDB_btn", start_btn)

        table_frame.grid_columnconfigure(0, weight=1)
        table_frame.grid_columnconfigure(1, weight=1)
        table_frame.grid_columnconfigure(2, weight=1)

    def UI_render_appProcesses(self,row):
        # Create a frame for the table2
        table_frame = ttk.Frame(self, padding="20", style="ProcessesList.TFrame")
        table_frame.grid(row=row, column=0, padx=0, pady=(0,1), sticky="nsew")

        
        for row, process_name in enumerate(self.processes, start=1):

            target_row = row


            # Process name
            ttk.Label(table_frame, text=process_name, style="PName.TLabel").grid(row=target_row, column=0, sticky='nsew', padx=5, pady=5)

            # Status text
            status_label = ttk.Label(table_frame, text=TRANSLATION["status_off"], style="StatusOff.TLabel")
            status_label.grid(row=target_row, column=1, sticky='nsew', padx=12, pady=5)
            
            self.UI_register(process_name, "status_label", status_label)

            # Buttons
            btn_frame = ttk.Frame(table_frame, style="ProcessesList.TFrame")
            btn_frame.grid(row=target_row, column=2, sticky='nsew', padx=12, pady=5)
            start_btn = ttk.Button(btn_frame, text=TRANSLATION["button_on"], command=lambda p=process_name: self.onBtnClick(p, "start_btn"), style="Log.TButton")
            start_btn.pack(side='left', padx=2)

            self.UI_register(process_name, "start_btn", start_btn)

            stop_btn = ttk.Button(btn_frame, text=TRANSLATION["button_off"], command=lambda p=process_name: self.onBtnClick(p, "stop_btn"), style="Log.TButton")
            stop_btn.pack(side='left', padx=2)
            self.UI_register(process_name, "stop_btn", stop_btn)

            # View Log only for game server
            """if process_name in ["goddess_y", "bishop_y", "s3relay_y", "jx_linux_y"]:
                log_btn = ttk.Button(btn_frame, text=TRANSLATION["button_log"], command=lambda p=process_name: self.onBtnClick(p, "log_btn"), style="Log.TButton")

                log_btn.pack(side='left', padx=2)
                self.UI_register(process_name, "log_btn", log_btn)"""

        table_frame.grid_columnconfigure(0, weight=1)
        table_frame.grid_columnconfigure(1, weight=1)
        table_frame.grid_columnconfigure(2, weight=1)     

    def UI_render_mainController(self,row): 
        # Main buttons
        mainMenu_frame = ttk.Frame(self,  style="MainController.TFrame", padding="15")
        mainMenu_frame.grid(row=row, column=0, sticky='nsew', pady=(0,0)) 
        start_all_btn = ttk.Button(mainMenu_frame, text=TRANSLATION["button_start_all"], command=lambda : self.onBtnClick("mainMenu", "start_btn"), style="StartAll.TButton")
        start_all_btn.pack(side='left', padx=10)
        stop_all_btn = ttk.Button(mainMenu_frame, text=TRANSLATION["button_stop_all"], command=lambda : self.onBtnClick("mainMenu", "stop_btn"), style="StopAll.TButton")
        stop_all_btn.pack(side='left', padx=10)
        users_btn = ttk.Button(mainMenu_frame, text=TRANSLATION["button_users"], command=lambda : self.onBtnClick("mainMenu", "users_btn"), style="Users.TButton")
        users_btn.pack(side='left', padx=(10,10))

        self.UI_register("mainMenu", "start_btn", start_all_btn)
        self.UI_register("mainMenu", "stop_btn", stop_all_btn)
        self.UI_register("mainMenu", "users_btn", users_btn)



    def UI_render_authorInfo(self,row):
        # Create a frame for the table1
        introText = ttk.Label(self, text="vinhttn", style="Author.TLabel")
        introText.grid(row=row, column=0, sticky='e', padx=10, pady=10)

    def UI_register(self, process_name, key, value):
        if process_name not in self.UI:
            self.UI[process_name] = {}
        self.UI[process_name][key] = value
        self.UI[process_name][key+"_isHidden"] = False


    def UI_execShowhideBtn(self, process_name, btnName, show):
        if not show and (not self.UI[process_name][btnName+"_isHidden"]):
            self.UI[process_name][btnName+"_isHidden"] = True
            self.UI[process_name][btnName].pack_forget()

        if show and (self.UI[process_name][btnName+"_isHidden"]):
            self.UI[process_name][btnName+"_isHidden"] = False
            self.UI[process_name][btnName].pack(side='left', padx=2)


    def UI_setShowBtn(self, process_name, btnName, btnStatus):
        
        if process_name in self.UI:                 
            if btnName in self.UI[process_name]:
                if not btnStatus:                 
                    return self.UI_execShowhideBtn(process_name, btnName, False)
                    
                else: 
                    return self.UI_execShowhideBtn(process_name, btnName, True)


    def UI_toggleButtons(self):


        hasMSSQL = self.hidden_processes["MSSQL"]["status"] 
        hasMySQL = self.hidden_processes["MySQL"]["status"] 
        hasWinPaysys = self.processes["PaySys"]["status"] 
        hasRelayServer = self.processes["RelayServer"]["status"] 
        hasGoddess =  self.processes["goddess_y"]["status"] 
        hasBishop =   self.processes["bishop_y"]["status"] 
        hasS3Relay = self.processes["s3relay_y"]["status"] 
        hasGS =   self.processes["jx_linux_y"]["status"] 

        hasAny = hasWinPaysys or hasRelayServer or hasGoddess or hasBishop or hasS3Relay or hasGS
        hasAll = hasWinPaysys and hasRelayServer and hasGoddess and hasBishop and hasS3Relay and hasGS

        self.UI_setShowBtn("mainMenu", "startDB_btn", not hasMSSQL or (not hasMySQL))
        self.UI_setShowBtn("mainMenu", "backup_btn", hasMSSQL and hasMySQL)

        """
        self.UI_setShowBtn("mainMenu", "stop_btn", True or hasAny)
        self.UI_setShowBtn("mainMenu", "start_btn", True or (hasMSSQL and hasMySQL and (not hasAll)))
        self.UI_setShowBtn("mainMenu", "changeDir_btn", not hasAny)
        self.UI_setShowBtn("mainMenu", "users_btn", True)

        for key in self.processes:
            self.UI_setShowBtn(key, "log_btn", False)
            self.UI_setShowBtn(key, "stop_btn", True)
            self.UI_setShowBtn(key, "start_btn", True)

        #Condition for Paysys + Relay win
        self.UI_setShowBtn("PaySys", "start_btn", hasMSSQL and (not hasWinPaysys))
        self.UI_setShowBtn("PaySys", "stop_btn", hasWinPaysys and (not hasGoddess) and (not hasBishop) and (not hasGS) and (not hasS3Relay))

        self.UI_setShowBtn("RelayServer", "start_btn", hasMSSQL and (not hasRelayServer))
    
        self.UI_setShowBtn("RelayServer", "stop_btn", hasRelayServer and (not hasGoddess) and (not hasBishop) and (not hasGS) and (not hasS3Relay))

        #Condition for Goddess
        self.UI_setShowBtn("goddess_y", "start_btn", hasMySQL and (not hasGoddess))
        self.UI_setShowBtn("goddess_y", "stop_btn", hasGoddess and (not hasBishop) and (not hasGS)  and (not hasS3Relay))

        #Condition for Bishop
        self.UI_setShowBtn("bishop_y", "start_btn", not hasBishop and hasWinPaysys)
        self.UI_setShowBtn("bishop_y", "stop_btn", hasBishop and (not hasGS) and (not hasS3Relay))

        #Condition for S3Relay
        self.UI_setShowBtn("s3relay_y", "start_btn", not hasS3Relay and hasWinPaysys and hasRelayServer and hasGoddess and hasBishop)
        self.UI_setShowBtn("s3relay_y", "stop_btn", hasS3Relay)

        #Condition for GS
        self.UI_setShowBtn("jx_linux_y", "start_btn", not hasGS and hasS3Relay)
        self.UI_setShowBtn("jx_linux_y", "stop_btn", hasGS)
        """

    def UI_updateStatusTxt(self, process_name, status):
        text = TRANSLATION["status_on"] if status else TRANSLATION["status_off"]
        if process_name in self.UI:
            if "status_label" in self.UI[process_name]:
                self.UI[process_name]["status_label"].config(text=text)
                self.UI[process_name]["status_label"].configure(style='Status'+('On' if status else 'Off')+'.TLabel')

              
    def _monitoring(self):
      
        # Check the status of each process
        for process_name in self.hidden_processes:
            status = self._monitoring_process(process_name)
            self.hidden_processes[process_name]["status"] = status
            self.UI_updateStatusTxt(process_name, status)
 
        # Check the status of each process
        for process_name in self.processes:
            status = self._monitoring_process(process_name)
            self.processes[process_name]["status"] = status
            self.UI_updateStatusTxt(process_name, status)

        self.UI_toggleButtons()
        self.after(2000, self._monitoring)  # Check every 2 seconds

    def _monitoring_process(self, process_name):
        if process_name == "MSSQL":
            process_name = "/opt/mssql/bin/sqlservr"
        if process_name == "MySQL":
            process_name = "mysqld"

        if process_name == "PaySys":
            process_name = "Sword3PaySys.exe"

        if process_name == "RelayServer":
            process_name = "S3RelayServer.exe"

        # Dummy implementation, replace with actual process checking logic
        # For example, using subprocess to check if the process is running
        try:
            output = subprocess.check_output(['pgrep', '-f', process_name])
            return bool(output)
        except subprocess.CalledProcessError:
            return False 

 
  
    def on_closing(self): 
        self.saveConfig()
        self.destroy()

    def saveConfig(self):
        save_dict_to_file(self.CONFIG, CONFIGFILE)


    def disableBtn(self, process_name, btnName, time):
        self.UI[process_name][btnName+"_timeout"] = now() + time
 

    def onBtnClick(self, area, section):
        # Has force hidden attached ?
        if area in self.UI: 
            if section+"_timeout" in self.UI[area]: 
                # Still inside force hidden? Do not allow click
                if self.UI[area][section+"_timeout"] > now():
                    return True

                
        if area == "mainMenu":
            

            if section == "changeDir_btn":
                folder_selected = filedialog.askdirectory(initialdir=self.CONFIG["directory"])
                if folder_selected:
                    self.CONFIG["directory"] = folder_selected
                    self.UI["mainMenu"]["changeDir_label"].config(text=folder_selected)
                    self.saveConfig()
                return True

            self.disableBtn(area, section, 3)
            if section == "start_btn":
                self.execWinCommand(["start"])
                return True
            if section == "stop_btn":
                self.execWinCommand(["stop"])
                return True          
            if section == "backup_btn":
                self.execCommand(["backup"])
                return True
            if section == "startDB_btn":
                self.execRawWinCommand("/root/serversetup/startup.sh",[])
                return True       
            if section == "users_btn":
                subprocess.Popen(['python3', APP_DIR_FULL+"/users.py"])
                return True                                            
            if section == "updateApp":
                self.execRawWinCommand(APP_DIR_FULL+"/../update.sh",[])
                self.on_closing()

                return True           
        else:
            
            self.disableBtn(area, section, 3)
            if section == "start_btn": 
                self.execCommand(["start", area.replace("_y","")])
                return True
            if section == "stop_btn":
                self.execCommand(["stop", area.replace("_y","")])
                return True                
            if section == "log_btn":
                self.execCommand(["status", area.replace("_y","")])
                return True 

    def execCommand(self, args):  
        env = os.environ.copy()
        env["GAMEPATH"] = self.CONFIG["directory"]
        result = subprocess.Popen(['bash', BASH_SCRIPT] + args, env=env)

    def execWinCommand(self, args):
        env = os.environ.copy()
        env["GAMEPATH"] = self.CONFIG["directory"]

        result = subprocess.Popen(['xfce4-terminal', '--tab', '--command', 'bash -c "{} {}"'.format(BASH_SCRIPT, ' '.join(args))], env=env)
         
    def execRawWinCommand(self, scriptLink, args):
        env = os.environ.copy()
        env["GAMEPATH"] = self.CONFIG["directory"]
        result = subprocess.Popen(['xfce4-terminal', '--tab',  '--command', 'bash -c "{} {}"'.format(scriptLink, ' '.join(args))], env=env)
if __name__ == "__main__":
    app = ProcessDashboard()
    app.mainloop()
