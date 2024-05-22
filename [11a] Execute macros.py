# -*- coding: utf-8 -*-
"""
Created on Fri Aug 11 14:41:59 2023

@author: K17765
"""

import win32com.client
import openpyxl
import requests


## DEFINING FUNCTIONS
# TO DOWNLOAD FILES

import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def download_file(url, destination):
    response = requests.get(url, verify=False,  timeout=1000)
    if response.status_code == 200:
        with open(destination, 'wb') as file:
            file.write(response.content)
        print("File downloaded successfully.")
    else:
        print("Failed to download the file.")
        
if __name__ == "__main__":
    file_url = r"https://portafolioinfdoctos.cnbv.gob.mx/Documentacion/minfo/040_15b_R2.xls"  # Replace with the actual file URL
    save_path = r"//Statadgef/darmacro/Data/Bank Data/Data/Raw040_15b_R2.xls"  # Replace with the desired save path and filename

    #Running program
    download_file(file_url, save_path)
        

# RUN MACROS INSIDE THE FILE AND CREATES A ...MOD FILE WITH VARIABLES     
        
def run_macro_on_protected_file(protected_file_path, macro_file_path, macro_name, source_range):
    excel = win32com.client.Dispatch("Excel.Application")
    excel.Visible = True  # Set to True if you want to see Excel while the macro runs
    
    try:
        macro_workbook = excel.Workbooks.Open(macro_file_path)
        cnbv_workbook = excel.Workbooks.Open(cnbv_file_path)
        macro_workbook.Application.Run("'" + macro_workbook.Name + "'!" + macro_name)
        macro_workbook.Close(False)  # Don't save changes to the macro workbook
    except Exception as e:
        print("Error running macro:", e)
        
     # Copy data from protected Excel file
    data_to_copy = cnbv_workbook.Sheets("BD").Range(source_range).Value
    
    # Create a new Excel file
    new_workbook = openpyxl.Workbook()
    new_sheet = new_workbook.active
    
    # Paste data into the new Excel file
    for row in data_to_copy:
        new_sheet.append(row)
        
        
    new_file_path = r"//Statadgef/darmacro/Data/Bank Data/Data/Raw/040_15b_R2_mod.xlsx"  # Specify the path for the new Excel file
    new_workbook.save(new_file_path)
    new_workbook.close()
    
    #cnbv_workbook.Save()
    cnbv_workbook.Close(False)  # Don't save changes to the protected workbook
    excel.Quit()
    
if __name__ == "__main__":
    cnbv_file_path = r'//Statadgef/darmacro/Data/Bank Data/Data/Raw/040_15b_R2.xls'  # Replace with your protected Excel file's path
    ob_macro_file_path = r'//Statadgef/darmacro/Data/Bank Data/Codes/Data Construction/(11-OB)Macros_ICAPUpdates.xlsm' # Replace with your macro Excel file's path
    macro_name = 'Módulo1.UpdatingIcap'  # Replace with the name of your macro
    source_range = 'G5:J15000'  # Specify the range of cells to copy from the protected Excel file

    #Running program
    run_macro_on_protected_file(cnbv_file_path, ob_macro_file_path, macro_name, source_range)
