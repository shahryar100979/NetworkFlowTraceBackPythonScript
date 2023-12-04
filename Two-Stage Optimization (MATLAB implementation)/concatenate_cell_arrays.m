function result_cellArray = concatenate_cell_arrays(cellArray1, cellArray2)

% Check the number of rows in each cell array
num_rows_cellArray1 = size(cellArray1, 1);
num_rows_cellArray2 = size(cellArray2, 1);

% Add an empty row to the second cell array if needed
if num_rows_cellArray1 > num_rows_cellArray2
    num_missing_rows = num_rows_cellArray1 - num_rows_cellArray2;
    empty_row = cell(1, size(cellArray2, 2));
    cellArray2 = [cellArray2; repmat(empty_row, num_missing_rows, 1)];
end

if num_rows_cellArray1 < num_rows_cellArray2
    num_missing_rows = num_rows_cellArray2 - num_rows_cellArray1 ;
    empty_row = cell(1, size(cellArray1, 2));
    cellArray1 = [cellArray1; repmat(empty_row, num_missing_rows, 1)];
end

% Concatenate the cell arrays horizontally
result_cellArray = [cellArray1, cellArray2];


