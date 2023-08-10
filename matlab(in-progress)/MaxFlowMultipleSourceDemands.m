function output = MaxFlowMultipleSourceDemands(input_data, ordinal_process, x_sol_mod)

% Your adjacency matrix, source, and sink
adjMatrix = x_sol_mod;  % Your adjacency matrix
source = size(x_sol_mod,1)-1;
sink = size(x_sol_mod,1);

[~, augmentedPaths] = fordFulkerson(adjMatrix, source, sink);

paths = zeros(numel(augmentedPaths), numel(ordinal_process));
flows = zeros(numel(augmentedPaths), 1);
for i = 1:length(augmentedPaths)
    path = augmentedPaths{i}.path(2:end-1);
    flow = augmentedPaths{i}.flow;
    disp(['Path: ' num2str(path) ', Flow: ' num2str(flow)]);

    paths(i,:) = path;
    flows(i,:) = flow;
end


cell_data = table2cell(input_data);
cols = [4,5,6];
trace_back = {};
exhausted_paths = paths;
output = {};

traced_back_deliveries = [];


delivery_counter = 1 ;

for i = 1:size(paths,1)

    if ismember(i,traced_back_deliveries)
        continue
    end

    % find delivery_flow
    indices = find(paths(:,end) == paths(i,end));


    tmp = [traced_back_deliveries, transpose(indices)];
    traced_back_deliveries = tmp ;


    delivery_path = paths(indices,:);
    delivery_flow = flows(indices,:);

    exhausted_paths(indices,:)=0;

    trace_back = [cell_data(paths(i,end), cols), sum(delivery_flow)];
    for j = size(delivery_path,2)-1:-1:1

        [unique_indices, quantity] = transformArrays(delivery_path(:,j), transpose(delivery_flow));

        trace_back = concatenate_cell_arrays(...
            [cell_data(unique_indices,cols), num2cell(quantity) ] , ...
            trace_back);
    end
    demand_counter = cell(size(trace_back,1),1);
    for j = 1:size(trace_back,1)
        if size(trace_back,1) > 1
            demand_counter{j} = sprintf('%d-%d', delivery_counter, j);
        else
            demand_counter{j} = sprintf('%d', delivery_counter);
        end
    end

    delivery_counter = delivery_counter + 1 ;

    tmp = [output; [trace_back , demand_counter]];
    output = tmp ;
end

