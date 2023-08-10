function [maxFlow, augmentedPaths] = fordFulkerson(adjMatrix, source, sink)
    residualGraph = adjMatrix;
    maxFlow = 0;
    augmentedPaths = {};

    while true
        [augmentingPath, augmentingFlow] = findAugmentingPath(residualGraph, source, sink);
        
        if isempty(augmentingPath)
            break;
        end
        
        augmentedPaths{end+1} = struct('path', augmentingPath, 'flow', augmentingFlow);
        maxFlow = maxFlow + augmentingFlow;
        
        % Update the residual graph capacities
        for i = 1:length(augmentingPath)-1
            u = augmentingPath(i);
            v = augmentingPath(i+1);
            residualGraph(u, v) = residualGraph(u, v) - augmentingFlow;
            residualGraph(v, u) = residualGraph(v, u) + augmentingFlow;
        end
    end
end

function [path, flow] = findAugmentingPath(residualGraph, source, sink)
    queue = source;
    visited = false(1, size(residualGraph, 1));
    parent = zeros(1, size(residualGraph, 1));
    flow = inf(1, size(residualGraph, 1));

    while ~isempty(queue)
        u = queue(1);
        queue(1) = [];
        visited(u) = true;

        for v = 1:size(residualGraph, 1)
            if ~visited(v) && residualGraph(u, v) > 0
                queue(end+1) = v;
                visited(v) = true;
                parent(v) = u;
                flow(v) = min(flow(u), residualGraph(u, v));
                
                if v == sink
                    path = [];
                    f = flow(sink);
                    while v ~= source
                        path = [v path];
                        u = parent(v);
                        f = min(f, residualGraph(u, v));
                        v = u;
                    end
                    path = [source path];
                    flow = f;
                    return;
                end
            end
        end
    end

    path = [];
    flow = 0;
end


