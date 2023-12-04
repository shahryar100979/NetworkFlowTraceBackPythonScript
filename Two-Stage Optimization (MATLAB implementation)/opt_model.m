
%% Instantiate Optimization model
NetworkFlowProblem = optimproblem("Description","Network FLow Trace Back",...
    "ObjectiveSense","min");

%% Decision Variable
% amount of outgoing flow from the nodes
u = optimvar("u", number_of_flows, ...
    number_of_flows, ...
    "LowerBound", 0, ...
    "UpperBound", max(input_data.Amount), ...
    "Type", "continuous");


%% Constraints

% upper bound of decision variables
for flow = 1:number_of_flows

    for_process = string(input_data.for_process{flow,1}); % identify the process
    if for_process == ordinal_process{end}
        u.UpperBound(flow,:) = 0 ; % since there should not be any outgoing flow from nodes of type delivery
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

    % identify feasible outgoing flows from the node
    feasible_flows = all([input_data.send_from_cnt == to_processing_cnt , ...
        input_data.for_process == next_process , input_data.Week >= week], 2);

    % adjust the upper bound of the decision variables
    u.UpperBound(flow,~feasible_flows) = 0;
    u.UpperBound(flow,feasible_flows) = amount;
end

% instantiate constraints
cons_a1 = optimconstr(1); % ensuring the total outgoing flows from a node equals to the amount of the node
cons_a2 = optimconstr(1); % ensuring the total incoming flows from a node equals to the total outgoing flows
cons_a3 = optimconstr(1); % ensuring the total incoming flows to the delivery node equals to the amount of delivery

cnt_1 = 1;
cnt_2 = 1;
for flow = 1:number_of_flows

    for_process = string(input_data.for_process{flow,1});
    if for_process == ordinal_process{end} % check whether the node is a delivery type
        incomings = find(u.UpperBound(:,flow)); % find all incoming flows
        cons_a3(cnt_1) = sum(u(incomings, flow),'all') == input_data.Amount(flow,1);
        cnt_1 = cnt_1 + 1 ;
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

    cons_a1(cnt_2) = sum(u(flow,feasible_flows),'all') == amount;

    if ~any(strcmp(for_process, ordinal_process([1,end])))
        incomings = find(u.UpperBound(:,flow));
        outgoings = find(u.UpperBound(flow,:));
        cons_a2(cnt_2) = sum(u(incomings, flow),'all') == sum(u(flow, outgoings),'all');
    elseif strcmp(for_process, ordinal_process(end))
        incomings = find(x.UpperBound(:,flow));
        cons_a2(cnt_2) = sum(u(incomings, flow),'all') == sum(u(flow, :),'all');
    end
    cnt_2 = cnt_2 + 1;
end

NetworkFlowProblem.Constraints.cons_a1 = cons_a1;
NetworkFlowProblem.Constraints.cons_a2 = cons_a2;
NetworkFlowProblem.Constraints.cons_a3 = cons_a3;

%% Penalize the number of paths from source to delivery
% we add a penalty to the objective function being minimized to count the number of edges; however, this turns the problem into MILP instead of LP

if penalize_number_of_flows
    is_non_negative = optimvar("is_non_negative", number_of_flows, ...
        number_of_flows, ...
        "LowerBound", 0, ...
        "UpperBound", 1, ...
        "Type", "integer");

    big_M = max(input_data.Amount);
    cons_non_negative = optimconstr(number_of_flows, number_of_flows);
    for i = 1:number_of_flows
        for j = 1:number_of_flows
            cons_non_negative(i,j) = u(i,j) <= big_M * is_non_negative(i,j);
        end
    end
    NetworkFlowProblem.Constraints.cons_non_negative = cons_non_negative;

    NetworkFlowProblem.Objective = sum(u,'all') + sum(is_non_negative, 'all');

    options = optimoptions('intlinprog',...
        'MaxTime', RunTime, ...
        'RelativeGapTolerance', 0.005, ...
        'ConstraintTolerance', 0.001) ;

else
    NetworkFlowProblem.Objective = sum(u,'all');

    options = optimoptions('linprog',...
        'MaxTime',RunTime,'Display','iter') ;
end


sol = solve(NetworkFlowProblem,'Options',options) ;



%% Identify solution
x_sol = round(sol.u, 4);