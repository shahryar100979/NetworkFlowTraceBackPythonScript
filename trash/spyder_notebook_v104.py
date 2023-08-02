import pandas as pd
pd.set_option('display.max_columns', None)

#######################################

# read input data
networkFlow = pd.read_excel(
    'NetworkFlowProblem-Data.xlsx', sheet_name='Input3')
networkFlow.columns = networkFlow.columns.str.lower()

#######################################


delta = 0.001 # tolerate small floating-point discrepancies

processing_steps = ['Sourcing', 'Conditioning',
                    'Treatment', 'Forwarding', 'Delivery']

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

#########################################################
# sort transaction based on week: assuming deliveries happen later at time
networkFlow_sorted = networkFlow.sort_values('week', ascending=False)

# identify demands
demands = networkFlow_sorted[networkFlow_sorted['for_process']
                             == processing_steps[-1]]


def trace_back_demand_to_source(demands):
    
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
            
            if demand_identifier == 8:
                print("behi")
            
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
        print(counter)
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

status = 0
while status == 0:
    demands = demands.sample(frac=1, random_state=42)
    output = trace_back_demand_to_source(demands)
    status = output["status"]

