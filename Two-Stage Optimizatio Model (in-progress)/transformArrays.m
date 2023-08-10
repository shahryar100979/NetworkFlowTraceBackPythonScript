function [unique_array_1, summed_array_2] = transformArrays(array_1, array_2)
    % Find unique values in array_1 without sorting
    [unique_values, ~, idx] = unique(array_1, 'stable');

    % Initialize the new array_2
    summed_array_2 = zeros(size(unique_values));

    % Loop through the unique values and sum the corresponding values in array_2
    for i = 1:length(unique_values)
        summed_array_2(i) = sum(array_2(idx == i));
    end

    % Return the transformed arrays
    unique_array_1 = unique_values;
end
