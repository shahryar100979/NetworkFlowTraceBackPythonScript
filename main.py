#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug  2 13:47:21 2023

@author: shahryarmonghasemi
"""

import pandas as pd
import os

from utils.utils import create_combined_dataframe, sort_formatted_out, write_output_into_excel, subtract_amount_if_exists
from utils.traceBackDemands import trace_back_demand_to_source
from utils.query import query

#######################################

#filename = 'NetworkFlowProblem-Data.xlsx'
#sheet_name = 'Input3'

file_path, sheet_name, filename = query()
    

# read input data
networkFlow = pd.read_excel(io = file_path, sheet_name = sheet_name)
networkFlow.columns = networkFlow.columns.str.lower()

#######################################


delta = 0.001 # tolerate small floating-point discrepancies

processing_steps = ['Sourcing', 'Conditioning',
                    'Treatment', 'Forwarding', 'Delivery']

#########################################################
# sort transaction based on week: assuming deliveries happen later at time
networkFlow_sorted = networkFlow.sort_values('week', ascending=False)

# identify demands
demands = networkFlow_sorted[networkFlow_sorted['for_process']
                             == processing_steps[-1]]

status = 0
attempt = 1
while status == 0:
    demands = demands.sample(frac=1, random_state=42)
    output = trace_back_demand_to_source(demands, processing_steps, networkFlow_sorted, delta)
    status = output["status"]
    print(output["message"])
    if not status:
        attempt += 1 
        print(f"\n\n================RESTART ({attempt} attempt(s))=============")

