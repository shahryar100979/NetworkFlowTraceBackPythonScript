#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug  2 14:01:21 2023

@author: shahryarmonghasemi
"""

import pandas as pd
from utils.utils import create_combined_dataframe, sort_formatted_out, write_output_into_excel, subtract_amount_if_exists

def trace_back_demand_to_source(demands, processing_steps, networkFlow_sorted, delta):
    
    failed_to_trace_back = False
    
    #instantiating variables
    all_combined_dfs = []
    counter = demands.shape[0]+1
    used_resources = pd.DataFrame() 


    for demand_identifier, demand in demands.iterrows():
        
        #demand = demands.loc[8, :]
        
        # get info on demand
        result = [{
            'Process': f'{processing_steps[-1]}',
            'Cnt': demand['to_processing_cnt'],
            'Week': demand['week'],
            'Amount': demand['amount'],
        
        }]
        
        send_from_cnt = [demand['send_from_cnt']]
        date_to_look_back = demand['week']
        
        # for each process
        for process in reversed(processing_steps[:-1]):
            
            print(f"Demand: {demand['amount']} @ {demand['to_processing_cnt']} at process: {process}")
            
            
            # check the ones hapenned at earlier weeks
            back_traces = networkFlow_sorted.loc[(networkFlow_sorted['to_processing_cnt'].isin(send_from_cnt)) &
                               (networkFlow_sorted['for_process'] == process) & 
                               (networkFlow_sorted['week'] <= date_to_look_back)]
            
            back_traces = back_traces.sort_values('week', ascending=False) # I would like to sort based on week

            if not used_resources.empty:
                 subtract_amount_if_exists(back_traces, used_resources)
            
                    
            if (process==processing_steps[0]) & \
                (back_traces.shape[0]==1) & \
                    (back_traces['amount'].sum() < demand['amount']):
                        back_traces['amount'] = demand['amount']
            
            
            #check for the amount
            if (back_traces['amount'].sum() + delta < demand['amount']) | (back_traces.empty):
                failed_to_trace_back =  True
                print(f"Error 100: demand was {demand['amount']}, greater than traced back flows, or no traces could be find for the demand.")
                break
            else:
                filled_demand = 0
                send_from_cnt = []
                rows_to_concat = []
                for index, row in back_traces.iterrows():
                    if row['amount'] == 0:
                        continue
                    if filled_demand < demand['amount']:
                        if filled_demand + row['amount'] > demand['amount']:
                            allocated_demand = demand['amount'] - filled_demand;
                            mod_row = row
                            mod_row['amount'] = allocated_demand
                            rows_to_concat.append(mod_row)
                            used_resources = pd.concat([used_resources, pd.DataFrame([mod_row])], ignore_index=True)
                            if row['week'] < date_to_look_back:
                                date_to_look_back = row['week']
                        else:
                            allocated_demand = row['amount']
                            rows_to_concat.append(row)
                            used_resources = pd.concat([used_resources, pd.DataFrame([row])], ignore_index=True)
                            if row['week'] < date_to_look_back:
                                date_to_look_back = row['week']
        
                        filled_demand += allocated_demand
                        send_from_cnt.append(row['send_from_cnt'])
                        result.append({
                            'Process': f'{process}',
                            'Cnt': row['to_processing_cnt'],
                            'Week': row['week'],
                            'Amount': allocated_demand,
                            })
                    
            
        counter -= 1
        print(f"demand {demands.shape[0]+1-counter} traced back out of {demands.shape[0]} demands\n")
        combined_df = create_combined_dataframe(result, counter)
        all_combined_dfs.append(combined_df)            

    for df in all_combined_dfs:
        if failed_to_trace_back:
            final_combined_df = write_output_into_excel(all_combined_dfs, filename = 'output.xlsx')
            return {"message": "failed to trace back all demands by given order",
                    "status": 0,
                    "output": final_combined_df}
        else:
            final_combined_df = write_output_into_excel(all_combined_dfs, filename = 'output.xlsx')
            return {"message": "successfully traced back all demands to source by the given order",
                    "status": 1,
                    "output": final_combined_df}