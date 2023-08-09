% Specify the file path and name
if ismac
    file_path = '../input/NetworkFlowProblem-Data.xlsx';
else
    file_path = '..\input\NetworkFlowProblem-Data.xlsx';
end

% Read the data from the Excel file
input_data = readtable(file_path, 'FileType','spreadsheet','Sheet','Input1');

%% Configurations
number_of_flows = size(input_data,1);
amounts = zeros(number_of_flows);

RunTime = 2*60*60 ; % maximum run time in seconds
ordinal_process = {'Sourcing', 'Conditioning', 'Treatment', 'Forwarding', 'Delivery'};

%% Optimization model
NetworkFlowProblem = optimproblem("Description","Network FLow Trace Back",...
    "ObjectiveSense","min");

% assignment decision variables: binary
x = optimvar("x",number_of_flows, ...
    number_of_flows, ...
    "LowerBound",0,"UpperBound",1,"Type","integer");

% capacity decision variables: continuous
u = optimvar("u",number_of_flows, ...
    number_of_flows, ...
    "LowerBound",0,"UpperBound",max(input_data.Amount),"Type","continuous");


%% Constraints
cons_a2 = optimconstr(1);
cons_a3 = optimconstr(1);
cons_a4 = optimconstr(1);
for flow = 1:number_of_flows
    for_process = string(input_data.for_process{flow,1});
    if for_process == ordinal_process{end}
        x.UpperBound(flow,:) = 0 ;
        u.UpperBound(flow,:) = 0 ;
        continue
    end
    send_from_cnt = string(input_data.send_from_cnt{flow,1});
    to_processing_cnt = string(input_data.to_processing_cnt{flow,1});
    week = input_data.Week(flow,1);
    amount = input_data.Amount(flow,1);

    next_process = find(ordinal_process(:) == for_process);
    if next_process ~= length(ordinal_process)
        next_process = string(ordinal_process{next_process + 1});
    end

    feasible_flows = all([input_data.send_from_cnt == to_processing_cnt , ...
        input_data.for_process == next_process , input_data.Week >= week], 2);

    x.UpperBound(flow,~feasible_flows) = 0;
    u.UpperBound(flow,~feasible_flows) = 0;
    u.UpperBound(flow,feasible_flows) = amount;
end

counter = 1 ;
cnt = 1;
for flow = 1:number_of_flows
    for_process = string(input_data.for_process{flow,1});
    if for_process == ordinal_process{end}
        incomings = find(x.UpperBound(:,flow));
        cons_a4(cnt) = sum(u(incomings, flow),'all') == input_data.Amount(flow,1);
        cnt = cnt + 1 ;
        continue
    end
    send_from_cnt = string(input_data.send_from_cnt{flow,1});
    to_processing_cnt = string(input_data.to_processing_cnt{flow,1});
    week = input_data.Week(flow,1);
    amount = input_data.Amount(flow,1);

    next_process = find(ordinal_process(:) == for_process);
    if next_process ~= length(ordinal_process)
        next_process = string(ordinal_process{next_process + 1});
    end

    feasible_flows = all([input_data.send_from_cnt == to_processing_cnt , ...
        input_data.for_process == next_process , input_data.Week >= week], 2);
    cons_a2(counter) = sum(u(flow,feasible_flows),'all') == amount;

    if ~any(strcmp(for_process, ordinal_process([1,end])))
        incomings = find(x.UpperBound(:,flow));
        outgoings = find(x.UpperBound(flow,:));
        cons_a3(counter) = sum(u(incomings, flow),'all') == sum(u(flow, outgoings),'all');
    elseif strcmp(for_process, ordinal_process(end))
        incomings = find(x.UpperBound(:,flow));
        cons_a3(counter) = sum(u(incomings, flow),'all') == sum(u(flow, :),'all');
    end
    counter = counter + 1;
end



NetworkFlowProblem.Constraints.cons_a2 = cons_a2;
NetworkFlowProblem.Constraints.cons_a3 = cons_a3;
NetworkFlowProblem.Constraints.cons_a4 = cons_a4;
NetworkFlowProblem.Objective = sum(u,'all');

options = optimoptions('linprog',...
    'MaxTime',RunTime,'Display','iter') ;

% options = optimoptions('intlinprog',...
%     'MaxTime',RunTime,'RelativeGapTolerance',0.005, 'ConstraintTolerance', 0.001) ;

sol = solve(NetworkFlowProblem,'Options',options) ;



%% Process output
x_sol = round(sol.u, 4);

% 
% cell_data = table2cell(input_data);
% 
% cols = [4,5,6,7];
% 
% deliveries = transpose(find(strcmp(cell_data(:,5), 'Delivery')));
% counter = 1 ;
% delivery_order = cell(1);
% output = {};
% 
% % for every delivery we would like to trace back it to its source based on given solution
% for delivery = 26%deliveries
% 
%     delivery_order{counter}{1} = delivery ;
%     delivery_order{counter}{2} = transpose(find(x_sol(:,delivery)));
%     quantity_delivery = cell_data(delivery, cols(end)); % quantity to be delivered
%     delivery_flow = cell_data(delivery, cols);
% 
%     quantities = {};
%     for del = delivery_order{counter}{2}
%         amount = sum(x_sol(del, delivery));
%         tmp = [quantities;amount];
%         quantities = tmp;
%     end
% 
%     delivery_flow = concatenate_cell_arrays(...
%         [cell_data(delivery_order{counter}{2}, cols(1:end-1)), ...
%         quantities], ...
%         delivery_flow);
% 
%     % for the remaining processes: Treatment, COnditioning, and Sourcing
%     for process = 3:numel(ordinal_process)
%         to_orders = delivery_order{counter}{process-1};
% 
%         delivery_order{counter}{process} = [];
%         for order = to_orders
%             tmp = [delivery_order{counter}{process}, transpose(find(x_sol(:,order)))];
%             delivery_order{counter}{process} = unique(tmp);
%         end
% 
%         required_deliveries = x_sol(delivery_order{counter}{process},to_orders);
% 
%         delivery_flow = concatenate_cell_arrays(...
%             [cell_data(delivery_order{counter}{process}, cols(1:end-1)), num2cell(required_deliveries)], ...
%             delivery_flow);
% 
%     end
%     counter = counter + 1 ;
% 
%     tmp = [output; delivery_flow];
%     output = tmp;
% end
% 
% 
% 
