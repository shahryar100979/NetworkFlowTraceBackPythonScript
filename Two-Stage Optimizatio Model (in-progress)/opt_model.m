
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


%% penalize number of non-negative values in u

is_non_negative = optimvar("is_non_negative",number_of_flows, ...
    number_of_flows, ...
    "LowerBound",0,"UpperBound",1,"Type","integer");

penalty_factor = 1e3;
big_M = 1e6;

cons_non_negative = optimconstr(number_of_flows, number_of_flows);
for i = 1:number_of_flows
    for j = 1:number_of_flows
        cons_non_negative(i,j) = u(i,j) <= big_M * is_non_negative(i,j);
    end
end


% NetworkFlowProblem.Objective = sum(u,'all') + penalty_factor * sum(is_non_negative, 'all');



NetworkFlowProblem.Constraints.cons_a2 = cons_a2;
NetworkFlowProblem.Constraints.cons_a3 = cons_a3;
NetworkFlowProblem.Constraints.cons_a4 = cons_a4;
% NetworkFlowProblem.Constraints.cons_non_negative = cons_non_negative;


NetworkFlowProblem.Objective = sum(u,'all');

options = optimoptions('linprog',...
    'MaxTime',RunTime,'Display','iter') ;

% options = optimoptions('intlinprog',...
%     'MaxTime',RunTime,'RelativeGapTolerance',0.005, 'ConstraintTolerance', 0.001) ;

sol = solve(NetworkFlowProblem,'Options',options) ;



%% Process output
x_sol = round(sol.u, 4);