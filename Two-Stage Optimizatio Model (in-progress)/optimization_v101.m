clear
clc
close all

% Specify the file path and name
if ismac
    file_path = '../input/NetworkFlowProblem-Data.xlsx';
else
    file_path = '..\input\NetworkFlowProblem-Data.xlsx';
end

sheet_name = 'Input5';
% Read the data from the Excel file
input_data = readtable(file_path, 'FileType','spreadsheet','Sheet',sheet_name);

%% Configurations
number_of_flows = size(input_data,1);
amounts = zeros(number_of_flows);

RunTime = 2*60*60 ; % maximum run time in seconds
ordinal_process = {'Sourcing', 'Conditioning', 'Treatment', 'Forwarding', 'Delivery'};

%% Develop and solve the optimization model:
opt_model

%% plot and save network graph
output_filename = [sheet_name, '_graph network', '.jpg'];

plot_delivery_graphs(input_data, ordinal_process, x_sol, output_filename)

%% add dummy
add_dummy
output_filename =[sheet_name, '_graph_network_with_dummy_nodes', '.jpg'];
plot_delivery_graphs_with_dummy(input_data, ordinal_process, x_sol_mod, output_filename)

%% trace back all deliveries
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



