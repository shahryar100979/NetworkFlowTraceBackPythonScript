#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug  2 13:47:29 2023

@author: shahryarmonghasemi
"""
import pandas as pd

# prepare the results based on the format of expected outputs
def create_combined_dataframe(data_list, counter):
    process_order = ['Sourcing', 'Conditioning', 'Treatment', 'Forwarding', 'Delivery']
    process_dfs = {process: None for process in process_order}
    
    for d in reversed(data_list):
        process = d['Process']
        if process in process_order:
            
            if process_dfs[process] is None:
                process_dfs[process] = pd.DataFrame(columns=data_list[0].keys())
           
            process_dfs[process] = pd.concat([process_dfs[process], pd.DataFrame([d])], ignore_index=True)

    combined_df = pd.concat(process_dfs.values(), axis=1)
    if combined_df.shape[0] > 1:
        combined_df['Demand'] = [f"{counter}-{counter+1}" for cnt, _ in combined_df.iterrows()]
    else:
        combined_df['Demand'] = f"{counter}"

    return combined_df

# sort dataframe based on demand identifier
def sort_formatted_out(final_combined_df):
    if final_combined_df['Demand'].str.contains('-').any():
        final_combined_df['main'] = final_combined_df['Demand'].str.split('-', expand=True)[0].astype(int)
        final_combined_df['sub'] = final_combined_df['Demand'].str.split('-', expand=True)[1].fillna(0).astype(int)
        final_combined_df = final_combined_df.sort_values(['main', 'sub'])
        final_combined_df = final_combined_df.drop(columns=['main', 'sub'])
    else:
        final_combined_df['main'] = final_combined_df['Demand'].astype(int)
        final_combined_df = final_combined_df.sort_values('main')
        final_combined_df = final_combined_df.drop(columns='main')
    
    final_combined_df['Demand'] = final_combined_df['Demand'].astype(str)

    return final_combined_df

# write output into excel file
def write_output_into_excel(all_combined_dfs, filename = 'output.xlsx'):
    # Concatenate the filtered DataFrames
    filtered_dfs = [df for df in all_combined_dfs if df.shape[1] == 21]
    final_combined_df = pd.concat(filtered_dfs, ignore_index=True, axis=0)
    
    # sort the output based on demand identifier
    final_combined_df = sort_formatted_out(final_combined_df)
    
    # write output into an excel
    final_combined_df.to_excel(filename, index=False)
    
    return final_combined_df


# update amount of used traces
def subtract_amount_if_exists(back_traces, used_resources):
    for index, row in back_traces.iterrows():
        mask = (used_resources['product'] == row['product']) & \
               (used_resources['treatment'] == row['treatment']) & \
               (used_resources['send_from_cnt'] == row['send_from_cnt']) & \
               (used_resources['to_processing_cnt'] == row['to_processing_cnt']) & \
               (used_resources['for_process'] == row['for_process']) & \
               (used_resources['week'] == row['week'])

        if not used_resources[mask].empty:
            back_traces.loc[index, 'amount'] -= used_resources.loc[mask, 'amount'].sum()
            if back_traces.loc[index, 'amount'] < 0.001:
                back_traces.loc[index, 'amount'] = 0.0
