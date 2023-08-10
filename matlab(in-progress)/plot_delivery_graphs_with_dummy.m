function plot_delivery_graphs_with_dummy(input_data, ordinal_process, x_sol_mod, output_filename)

%% plot with dummies
graph = digraph(x_sol_mod);


LWidths = 5*graph.Edges.Weight/max(graph.Edges.Weight);
graph_plot = plot(graph, 'Layout', 'layered',  'EdgeLabel', graph.Edges.Weight, 'LineWidth',LWidths);

graph_plot.Marker = 's';
graph_plot.NodeColor = 'r';
graph_plot.MarkerSize = 5;
graph_plot.ArrowSize=5;
graph_plot.EdgeFontSize=5;
graph_plot.NodeFontSize=4;
graph_plot.NodeFontWeight="bold";


% Adjust the azimuth and elevation angles to rotate the figure
azimuth_angle = 270;     % Change this angle as needed
elevation_angle = 90;   % Change this angle as needed
view(azimuth_angle, elevation_angle);

node_labels = cell(numel(input_data.to_processing_cnt), 1);
for node = 1:numel(node_labels)

    node_labels{node} = char(string(input_data.to_processing_cnt{node}) + ...
        "\newline" + ...
        "week:" + string(input_data.Week(node)));
end
node_labels{end+1} = 'Dummy Origin';
node_labels{end+1} = 'Dummy Destination';


graph_plot.NodeLabel = node_labels;

for process = 1:numel(ordinal_process)
    x_location = max(graph_plot.XData)+1 ;
    y_location = 5.1 - process + 2;
    text(gca, x_location, y_location, ordinal_process{process}, 'FontSize', 10);
end

% Set the export resolution (DPI)
export_dpi = 400;

% Export the figure as a JPEG image with the specified DPI
print(output_filename, '-djpeg', ['-r' num2str(export_dpi)]);

