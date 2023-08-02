import pandas as pd
pd.set_option('display.max_columns', None)

delta = 0.001

processing_steps = ['Sourcing', 'Conditioning',
                    'Treatment', 'Forwarding', 'Delivery']

def create_combined_dataframe(data_list, demand_identifier):
    
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
        combined_df['Demand'] = [f"{demand_identifier}-{counter+1}" for counter, _ in combined_df.iterrows()]
    else:
        combined_df['Demand'] = f"{demand_identifier}"

    return combined_df



def subtract_amount_if_exists(back_traces, used_resources):
    for index, row in back_traces.iterrows():
        # Filter used_resources based on the specified columns
        mask = (used_resources['product'] == row['product']) & \
               (used_resources['treatment'] == row['treatment']) & \
               (used_resources['send_from_cnt'] == row['send_from_cnt']) & \
               (used_resources['to_processing_cnt'] == row['to_processing_cnt']) & \
               (used_resources['for_process'] == row['for_process']) & \
               (used_resources['Week'] == row['Week'])

        # Check if the row exists in used_resources
        if not used_resources[mask].empty:
            # Subtract the value of ['Amount'] in back_traces from used_resources
            used_resources.loc[mask, 'Amount'] -= row['Amount']


# read input data
networkFlow = pd.read_excel(
    'NetworkFlowProblem-Data.xlsx', sheet_name='Input1')

# sort transaction based on week: assuming deliveries happen later at time
networkFlow_sorted = networkFlow.sort_values('Week', ascending=False)

# find demands
demands = networkFlow_sorted[networkFlow_sorted['for_process']
                             == processing_steps[-1]]

all_combined_dfs = []

counter = demands.shape[0]+1
#for demand_identifier, demand in demands.iterrows():
    
demand = demands.loc[31, :]

# get info on demand
result = [{
    'Process': f'{processing_steps[-1]}',
    'Cnt': demand['to_processing_cnt'],
    'Week': demand['Week'],
    'Amount': demand['Amount'],

}]

send_from_cnt = [demand['send_from_cnt']]

used_resources = pd.DataFrame() 

# for each process
for process in reversed(processing_steps[:-1]):
    
    print(f"Demand: {demand['Amount']} @ {demand['to_processing_cnt']} at process: {process}")
    
    # check the ones hapenned at earlier weeks
    back_traces = networkFlow.loc[(networkFlow_sorted['to_processing_cnt'].isin(send_from_cnt)) &
                       (networkFlow_sorted['for_process'] == process) & 
                       (networkFlow_sorted['Week'] <= demand['Week'])]
    
    back_traces = back_traces.sort_values('Week', ascending=False) # I would like to sort based on week
    
    if not used_resources.empty:
        subtract_amount_if_exists(back_traces, used_resources)
    
    #check for the amount
    if (back_traces['Amount'].sum() + delta < demand['Amount']) | (back_traces.empty):
        print(f"Error 100: demand was {demand['Amount']}, greater than traced back flows, or no traces could be find for the demand.")
        break
    else:
        filled_demand = 0
        send_from_cnt = []
        rows_to_concat = []
        for index, row in back_traces.iterrows():
            if filled_demand < demand['Amount']:
                if filled_demand + row['Amount'] > demand['Amount']:
                    allocated_demand = demand['Amount'] - filled_demand;
                    mod_row = row
                    mod_row['Amount'] = allocated_demand
                    rows_to_concat.append(mod_row)
                else:
                    allocated_demand = row['Amount']
                    rows_to_concat.append(row) 

                filled_demand += allocated_demand
                send_from_cnt.append(row['send_from_cnt'])
                result.append({
                    'Process': f'{process}',
                    'Cnt': row['to_processing_cnt'],
                    'Week': row['Week'],
                    'Amount': allocated_demand,
                    })
            
        if rows_to_concat:
            used_resources = pd.concat([used_resources] + rows_to_concat, ignore_index=True, axis=1)
            #used_resources = used_resources.transpose()

used_resources = used_resources.transpose()
        
counter -= 1
print(counter)
combined_df = create_combined_dataframe(result, counter)
all_combined_dfs.append(combined_df)


final_combined_df = pd.concat(all_combined_dfs, ignore_index=True, axis=0)

# Assuming 'df' is your DataFrame and 'column' is the name of the column to sort.
final_combined_df['main'] = final_combined_df['Demand'].str.split('-', expand=True)[0].astype(int)
final_combined_df['sub'] = final_combined_df['Demand'].str.split('-', expand=True)[1].fillna(0).astype(int)
final_combined_df = final_combined_df.sort_values(['main', 'sub'])

# Remove the temporary columns when done
final_combined_df = final_combined_df.drop(columns=['main', 'sub'])


#final_combined_df.sort_values(by=final_combined_df.columns[-1], inplace=True, ascending=True)
#final_combined_df = final_combined_df.iloc[::-1]
final_combined_df.to_excel('alaki.xlsx', index=False)

