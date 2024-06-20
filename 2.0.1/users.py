import tkinter as tk
from tkinter import messagebox
from tkinter import ttk
import time
import subprocess
import json
import socket
import os
from tkinter import filedialog
import mysql.connector
import pyodbc
from tkinter.tix import *
import hashlib

# Define connection parameters
mysql_host = "127.0.0.1"
mysql_user = "root"
mysql_password = "1234560123"
mysql_database = "server1"

mssql_server = "127.0.0.1"
mssql_database = "account_tong"
mssql_username = "SA"
mssql_password = "SAJx123456"


def connect_to_mysql(host, user, password, database):
    """Connects to a MySQL server and returns the connection object."""
    # Connection string with the ODBC Driver name
    connection_string = f"DRIVER={{MySQL ODBC 8.4 Unicode Driver}};SERVER={host};DATABASE={database};UID={user};PWD={password};"

    try:
        connection = pyodbc.connect(connection_string)
        print("Connected to MySQL database!")
        return connection
    except pyodbc.Error as ex:
        print("Error connecting to database:", ex)
        return None

def connect_to_mssql(server, database, username, password):
  """Connects to a MSSQL server and returns the connection object."""
  try:
    connection_string = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}"
    connection = pyodbc.connect(connection_string)
    return connection
  except pyodbc.Error as err:
    print("Error connecting to MSSQL:", err)
    return None


def execute_query(connection, query, noresult=False):
  """Executes a query on the provided connection and returns the results."""
  try:
    connection.autocommit = True

    cursor = connection.cursor()
    cursor.execute(query)
    if (not noresult):
        result = cursor.fetchall()
    
    cursor.close()

    if not noresult:
        return result
    return None
  except Exception as err:
    print("Error executing query:", err)
    return None



# Connect to MySQL and MSSQL servers
mysql_connection = connect_to_mysql(mysql_host, mysql_user, mysql_password, mysql_database)
mssql_connection = connect_to_mssql(mssql_server, mssql_database, mssql_username, mssql_password)
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

def applyTheme(target ):

    menuColor = "#e5f3ff"
    listBgColor = "#ececec"
    # Apply a theme
    style = ttk.Style(target )
    style.theme_use('clam')  # You can change to 'alt', 'clam', 'default', etc.
    
    style.configure("TLabel", background="#ffffff", foreground="#333", borderwidth=0, font=("Helvetica", 12,"normal"))
    
    style.configure("PName.TLabel", background=listBgColor,  foreground="#000", font=("Helvetica", 12,"bold"), borderwidth=0) 
    style.configure("UserN.TLabel", background=listBgColor, foreground="#000", font=("Helvetica", 12,"normal"), borderwidth=0) 

    style.configure("SectionHeader.TLabel", background=menuColor, foreground="#1f73b7", font=("Helvetica", 16,"bold"), borderwidth=0)

    style.configure("General.TEntry", width=10)
    style.configure("TFrame", background="#ffffff", borderwidth=0)

    style.configure("SectionHeader.TFrame", background=menuColor, borderwidth=0) 
    style.configure("MainController.TFrame", background="#ffffff", borderwidth=0)
    style.configure("ProcessesList.TFrame", background=listBgColor, borderwidth=1) 

    style.configure("DeleteAcc.TButton", width=3, background="#cc3340", foreground="#ffffff", borderwidth=1, relief="solid", bordercolor="#cc3340")
    style.configure("StartAll.TButton", width=10, background="#1f73b7", foreground="#ffffff", borderwidth=1, relief="solid", bordercolor="#1f73b7")
    style.configure("Log.TButton", width=3, background="#ffffff", foreground="#1f73b7", borderwidth=0, relief="solid", bordercolor="#1f73b7")

    style.map("StartAll.TButton", background=[('active', '#144A75')])
    style.map("DeleteAcc.TButton", bordercolor=[('active', '#68232c')], background=[('active', '#68232c')])        
    style.map("Log.TButton", bordercolor=[('active', '#1F73B7')])

class ScrollableFrame:
    """
    # How to use class
    from tkinter import *
    obj = ScrollableFrame(master,height=300 # Total required height of canvas,width=400 # Total width of master)
    objframe = obj.frame
    # use objframe as the main window to make widget
    """
    def __init__ (self,master,width,height,mousescroll=0):
        self.mousescroll = mousescroll
        self.master = master
        self.height = height
        self.width = width
        self.main_frame = Frame(self.master)
        self.main_frame.pack(fill=BOTH,expand=1)

        self.scrollbar = Scrollbar(self.main_frame, orient=VERTICAL)
        self.scrollbar.pack(side=RIGHT,fill=Y)

        self.canvas = Canvas(self.main_frame,yscrollcommand=self.scrollbar.set, background="#ececec")
        self.canvas.pack(expand=True,fill=BOTH)

        self.scrollbar.config(command=self.canvas.yview)

        self.canvas.bind('<Configure>', lambda e: self.canvas.configure(scrollregion = self.canvas.bbox("all")))

        self.frame = Frame(self.canvas,width=self.width,height=self.height, background="#ececec", borderwidth=1)
        self.frame.pack(expand=True,fill=BOTH)
        self.canvas.create_window((0,0), window=self.frame, anchor="nw")

        self.frame.bind("<Enter>", self.entered)
        self.frame.bind("<Leave>", self.left)

        applyTheme(self.frame)
        applyTheme(self.master)
        applyTheme(self.canvas)
        applyTheme(self.main_frame)

    def destroy(self):
        self.main_frame.destroy()
        self.frame.destroy()
        self.canvas.destroy()
        self.scrollbar.destroy()

    def _on_mouse_wheel(self,event):
        self.canvas.yview_scroll(-1 * int((event.delta / 120)), "units")

    def entered(self,event):
        if self.mousescroll:
            self.canvas.bind_all("<MouseWheel>", self._on_mouse_wheel)
        
    def left(self,event):
        if self.mousescroll:
            self.canvas.unbind_all("<MouseWheel>")

class ProcessDashboard(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title(TRANSLATION["app_title"] + " " + TRANSLATION["app_version"] + " - vinhttn")
        self.geometry("700x600")
        self.resizable(False, True)  # Make the window not resizable

        # Set the background color of the main window
        self.configure(bg='#ffffff')
        self.protocol("WM_DELETE_WINDOW", self.on_closing)

        applyTheme(self)
        frame = self

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
        self.UI_render_mainHeader(1, frame)


        # Check if connections are successful
        if not mysql_connection or not mssql_connection:
            self.UI_render_db_error(2, frame)

            return

        self.UI_render_mainController(2, frame)
        self.UI_render_appProcesses(3, frame)
              
        # Adjust the sections
        for i in range(1,3):
            self.grid_rowconfigure(i, weight=0)
        self.grid_rowconfigure(3, weight=1)
        self.grid_columnconfigure(0, weight=1) 
  


    
    def UI_render_mainHeader(self, row, frame):
        table_frame = ttk.Frame(frame, padding="15", style="SectionHeader.TFrame")
        table_frame.grid(row=row, column=0, sticky="nsew")

        # Create a frame for the table1
        ipText = ttk.Label(table_frame, text="QuanLyUsers", style="SectionHeader.TLabel")
        ipText.pack(side='left', padx=(0,5))

 
     
    def UI_render_appProcesses(self,row, frame):
 
         

        if "win_frame" in self.UI:
            self.UI["win_frame"].destroy()

        # Create a frame for the table2
        table_frame = ttk.Frame(frame, padding="20", style="ProcessesList.TFrame")
        table_frame.grid(row=row, column=0, padx=0, pady=(0,1), sticky="nsew")
 
        win = ScrollableFrame(table_frame, width=700, height=600)
        self.UI["win_frame"] = win
        table_frame_inner = win.frame

        

        # Execute queries and retrieve results
        mssql_result = execute_query(mssql_connection, "SELECT cAccName FROM Account_Info ORDER by cAccName ASC;")

        target_row = 0

        ttk.Label(table_frame_inner, text="User", style="PName.TLabel").grid(row=target_row, column=1, sticky='nsew', padx=5, pady=5)
        ttk.Label(table_frame_inner, text="Nhân vật", style="PName.TLabel").grid(row=target_row, column=2, sticky='nsew', padx=5, pady=5)

        if mssql_result:
            for item in mssql_result:
                for uname in item:
                    target_row = target_row + 1
                    
                    # Process name
                    ttk.Label(table_frame_inner, text=uname, style="UserN.TLabel").grid(row=target_row, column=1, sticky='ew', padx=5, pady=5)
                    ttk.Button(table_frame_inner, text="Xóa", command=lambda p=uname: self.deleteAcc(p), style="DeleteAcc.TButton").grid(row=target_row, column=0, sticky='ew', padx=5, pady=5)


                    udata_result = execute_query(mysql_connection, "SELECT ID, RoleName FROM Role WHERE Account='{}' ORDER BY RoleName ASC;".format(uname))
                    if udata_result:
                        c_frame = ttk.Frame(table_frame_inner, padding="20", style="ProcessesList.TFrame")
                        c_frame.grid(row=target_row, column=2, padx=0, pady=(0,1), sticky="e")
                        crow = 0
                        for each in udata_result:
                            cid = each[0]
                            cname = each[1]
                            ttk.Label(c_frame, text=cname, style="UserN.TLabel").pack(side='left', padx=5)
                            ttk.Button(c_frame, text="Xóa", command=lambda p=cid: self.deleteChar(p), style="Log.TButton").pack(side='left', padx=(5, 20))
                            crow = crow + 1 
 


    def UI_render_db_error(self,row, target): 
        # Main buttons
        mainMenu_frame = ttk.Frame(target,  style="MainController.TFrame", padding="15")
        mainMenu_frame.grid(row=row, column=0, sticky='nsew', pady=(0,0)) 

        status_label = ttk.Label(mainMenu_frame, text="Không thể kết nối đến DB")
        status_label.pack(side='left', padx=10)
         

    def UI_render_mainController(self,row,target): 
        # Main buttons
        mainMenu_frame = ttk.Frame(target,  style="MainController.TFrame", padding="15")
        mainMenu_frame.grid(row=row, column=0, sticky='nsew', pady=(0,0)) 

        status_label = ttk.Label(mainMenu_frame, text="User")
        status_label.pack(side='left', padx=10)
        
        userName = tk.Entry(mainMenu_frame, width=10)
        userName.pack(side='left', padx=10)

        status_label = ttk.Label(mainMenu_frame, text="Pass1")
        status_label.pack(side='left', padx=10)

        userPass = tk.Entry(mainMenu_frame, width=10)
        userPass.pack(side='left', padx=10)

        status_label = ttk.Label(mainMenu_frame, text="Pass2")
        status_label.pack(side='left', padx=10)

        userPass2 = tk.Entry(mainMenu_frame, width=10)
        userPass2.pack(side='left', padx=10)

        create_user = ttk.Button(mainMenu_frame, text="Thêm", command=lambda  : self.newUser(userName.get(), userPass.get(), userPass2.get()), style="StartAll.TButton")
        create_user.pack(side='left', padx=(10,10))

        create_user = ttk.Button(mainMenu_frame, text="F5", command=lambda  : self.reloadList(), style="Log.TButton")
        create_user.pack(side='left', padx=(10,10))

        self.UI_register("mainMenu", "create_user", create_user)

 
    def reloadList(self):
        self.UI_render_appProcesses(3, self)


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

  
    def deleteChar(self, cid):
        execute_query(mysql_connection, "DELETE FROM `Role` WHERE ID = '{}';".format(cid), True)
        self.reloadList()

        return True 
    def deleteAcc(self, accName):
        execute_query(mysql_connection, "DELETE FROM `Role` WHERE Account = '{}';".format(accName), True)
        execute_query(mssql_connection, "DELETE FROM Account_Info WHERE cAccName = '{}';".format(accName), True)
        execute_query(mssql_connection, "DELETE FROM Account_Habitus WHERE cAccName = '{}';".format(accName), True) 
        self.reloadList()

        return True 
  
    def newUser(self, accName, accPass, accPass2):


        # Create an MD5 hash object
        md5_hash = hashlib.md5()
        md5_hash.update(accPass.encode())
        passmd52 = md5_hash.hexdigest()

        md5_hash = hashlib.md5()
        md5_hash.update(accPass2.encode())
        passmd51 = md5_hash.hexdigest()


        udata_result = execute_query(mssql_connection, "SELECT COUNT(*) FROM Account_Info WHERE cAccName='{}';".format(accName))
        if udata_result:
            if udata_result[0][0] == 0:

                # Create first
                execute_query(mssql_connection, "INSERT INTO Account_Info (cAccName,cSecPassWord, cPassWord,nExtPoint,nExtPoint1,nExtPoint2,nExtPoint3,nExtPoint4,nExtPoint5,nExtPoint6,nExtPoint7,iOTPSessionLifeTime,iServiceFlag,bIsBanned,bParentalControl,bIsUseOTP) VALUES ('{}','{}','{} ','1','0','0','0','0','0','0','0','0','0','0', '0', '0');".format(accName, passmd51, passmd52), True)
                execute_query(mssql_connection, "INSERT INTO Account_Habitus(cAccName,dEndDate,iLeftSecond) VALUES('{}',DATEADD(YEAR, 10, GETDATE()),'{}');".format(accName, 3600 * 24 * 365 * 10), True)

            else:
                # Force update pass in case we want to update
                execute_query(mssql_connection, "Update Account_Info SET cSecPassWord='{}', cPassWord='{}' WHERE cAccName = '{}';".format(passmd51, passmd52, accName), True)
        self.reloadList()

        return True

    def on_closing(self): 
        # Close connections
        if mysql_connection:
            mysql_connection.close()
        if mssql_connection:
            mssql_connection.close()
        self.destroy()
  
  
         
 
if __name__ == "__main__":
    app = ProcessDashboard()
    app.mainloop()
