
% identify sourcing nodes
sourcing_nodes = transpose(find(strcmp(input_data.for_process, ordinal_process{1})));
dummy_origin = zeros(1,size(x_sol,2));
for node = sourcing_nodes
    
    outgoing_quantity = sum(x_sol(node,:), 'all');
    dummy_origin(1,node) = outgoing_quantity;


end
dummy_origin = [dummy_origin, 0, 0];


delivery_nodes = transpose(find(strcmp(input_data.for_process, ordinal_process{end})));
dummy_destination = zeros(size(x_sol,2),1);
for node = delivery_nodes
    
    outgoing_quantity = sum(x_sol(:,node), 'all');
    dummy_destination(node,1) = outgoing_quantity;

    % dummy_destination(node,1) = input_data.Amount(node);

end

dummy_destination =  [dummy_destination; 0; 0];

x_sol_mod = [x_sol; zeros(2,size(x_sol,2))];
x_sol_mod = [x_sol_mod, zeros(size(x_sol_mod,1),2)];


x_sol_mod(end-1,:) = dummy_origin;
x_sol_mod(:,end) = dummy_destination;



