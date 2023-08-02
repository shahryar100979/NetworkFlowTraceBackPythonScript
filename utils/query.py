#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug  2 14:30:10 2023

@author: shahryarmonghasemi
"""

import pandas as pd
import os

def query():
    while True:
        filename = input("\nEnter the input file name (type skip if you'd like to use NetworkFlowProblem-Data.xlsx): ")
        if filename == "skip":
            filename = "NetworkFlowProblem-Data.xlsx"
        file_path = os.path.join("input", filename)
    
        # Check if the file exists
        if not os.path.exists(file_path):
            print("\n\t\t\t\tError 404: File does not exist. Please try again.")
        else:
            xls = pd.ExcelFile(file_path)
    
            # Get the list of sheet names
            sheet_names = xls.sheet_names
    
            # Filter the sheet names that start with "input" or "Input"
            filtered_sheet_names = [sheet_name for sheet_name in sheet_names if sheet_name.lower().startswith("input")]
    
            # Print the list of filtered sheet names
            if not filtered_sheet_names:
                print("No sheets found with names starting with 'input' or 'Input'.")
            else:
                print("\n Please type in a sheetname from the list below:")
                for sheet_name in filtered_sheet_names:
                    print(sheet_name)
    
            # Ask for the user to input a sheet name
            sheet_name = input("Enter the sheet name: ")
            
            # Exit the loop as the file and sheet names are valid
            break
    
    return file_path, sheet_name, filename