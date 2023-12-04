%% Initialization
clear
clc
close all

%% Parameters
file_name = 'NetworkFlowProblem-Data.xlsx';
sheet_name = 'Input1';
penalize_number_of_flows = true; % this ensurs the solution to have the minimum number of edges


%% Read Input Data

if ismac
    file_path = ['../input/', file_name];
else
    file_path = ['..\input\' , file_name];
end


% Read the data from the Excel file
input_data = readtable(file_path, 'FileType','spreadsheet','Sheet',sheet_name);

%% Configurations
number_of_flows = size(input_data,1);

RunTime = 2*60*60 ; % maximum run time in seconds
ordinal_process = {'Sourcing', 'Conditioning', 'Treatment', 'Forwarding', 'Delivery'};

%% Develop and solve the optimization model:
opt_model

%% plot and save network graph
output_filename = [sheet_name, '_graph network', '.jpg'];

plot_delivery_graphs(input_data, ordinal_process, x_sol, output_filename)

%% add dummy source and sink
add_dummy

output_filename =[sheet_name, '_graph_network_with_dummy_nodes', '.jpg'];
figure
plot_delivery_graphs_with_dummy(input_data, ordinal_process, x_sol_mod, output_filename)

%% trace back all deliveries and generate output files
output = MaxFlowMultipleSourceDemands(input_data, ordinal_process, x_sol_mod);

header = {
    'Process1', 'Cnt1', 'Week1', 'Amount1', ...
    'Process2', 'Cnt2', 'Week2', 'Amount2', ...
    'Process3', 'Cnt3', 'Week3', 'Amount3', ...
    'Process4', 'Cnt4', 'Week4', 'Amount4', ...
    'Process5', 'Cnt5', 'Week5', 'Amount5', ...
    'Demand Number'
};


tableData = cell2table(output, 'VariableNames', header(1, :));
fileName = [sheet_name, '_trace_backs', '.xlsx'];
writetable(tableData, fileName);



