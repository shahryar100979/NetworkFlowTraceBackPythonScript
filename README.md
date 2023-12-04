# Network Flow Trace Back Problem

This project focuses on solving network flow trace back problems given flows from source country to demand country for different demands. Each flow from source country to demand country should go through 5 different processing steps: Sourcing, Conditioning, Treatment, Forwarding and Delivery. We would like to trace back each demand to its source. Below is an example of given input network flow, wehre each node represents a process (i.e., one row of data), each edge represents a possible outgoing flow, and edge weight reperesents the maximum possible outflow. Obviously, the incoming and outgoing flows from each node are not equal, since edge weights do not reperesent the actual flows, but they are just maximum possible values based on given data.

![Network Flow Example](images/sampleGivenNetworkFlow.jpg)
**Figure Description: A sample of network configuration based on given input data (note: edge flows reperesent maximum flow, but not necessarily feasible or actual flows).**

## Proposed Solutions

Two solution techniques are developed:

- (1) Depth-First Search (DFS) Algorithm, and
- (2) Two-Stage Linear Programing (LP) Optimization Model

**Depth-First Search (DFS) Model:** The model traces back the path of each demand node to its source in the network. It takes input data from an Excel file 'NetworkFlowProblem-Data.xlsx' and uses Pandas for efficient data frame handling. The model employs a heuristic iterative DFS approach. In each iteration, it attempts to trace back the path for every demand node to a source, in a specified order. It keeps track of identified paths. If a demand node cannot be traced back fully, it is reordered to a higher priority for the next iteration. This iterative DEMAND reordering and path traceback process repeats until all demands have been successfully traced back to their respective sources. The final output is the full path from each demand to source. This heuristic DFS enables the algorithm to handle situations where cyclical paths may prevent tracing back certain demands. By reprioritizing unsuccessfully traced demands in each iteration, it ensures every demand path can be identified.

**Two-Stage Linear Programing (LP) Optimization Model:** The model uses a two-stage optimization approach to maximize flow through a network with multiple sources and sinks. First, a linear programming (LP) model is developed based on graph representation of the network. The nodes represent known flows, and edges represent flow capacity between nodes. Flow conservation constraints are added to ensure incoming and outgoing flows balance at each node. The LP model identifies a feasible flow solution. Next, the flow network is transformed into a single source, single sink maximum flow problem by adding dummy source and sink nodes. This is done because there are efficient, polynomial-time algorithms like Ford-Fulkerson to solve the maximum flow problem. By transforming into this well-studied form, the model can leverage these existing algorithms to efficiently find the optimal solution. The Ford-Fulkerson algorithm is then applied to identify the maximum flow and paths from source to sink. This two-stage approach combines the power of LP optimization and max-flow algorithms to solve the multi-source, multi-sink maximum flow problem.

![Network Flow Example](images/networkFlowExample.jpg)
**Figure Description: An example of a network flow from source country to demand country for different demands (results of LP model).**

![Network Flow Example](images/Input1_graph_network_with_dummy_nodes.jpg)
**Figure Description: Transformation of a multiple source, multiple sink maximum flow network into a single source and sink flow network. Dummy nodes are added to consolidate the sources and sinks.**

## Requirements

- Python 3.9.17, os, pandas
- MATLAB 2023a & Gurobi 10.0.0 (optional if you would like to use the two-stage optimization model)

# Depth-First Search (DFS) Algorithm

## How to run?

1. Ensure that the 'NetworkFlowProblem-Data.xlsx' file is located in the 'input' folder. Or you could provide your excel file with a sheet name that starts with "Input" in the 'input' folder.

2. **Run the Python script 'main.py' in the terminal**.

3. The script will prompt for the name of the Excel file. Enter the file name (followed by .xlsx) and press 'Enter'. In case you would like to use the default file you could **type 'skip'** and it uses 'NetworkFlowProblem-Data.xlsx' if found in the 'input' folder. The script will then show the list if sheets starting with 'Input<>', and then you need to type in which sheetname to use.

4. The script will then perform the trace back process for the demands and generate the results saved in 'output.xlsx' file in the root directory.

5. If the trace back is successful for all demands, the script will display "Successfully traced back all demands to source by the given order."

6. If the trace back fails for any demand, the script will display "Failed to trace back all demands by given order."

7. The script will also create additional attempts if the trace back fails, ensuring a successful trace back for all demands.

8. The sample of outputs can be found in folder 'sample of outputs'.

## Overview of algorithm

1. Import the necessary libraries, including pandas and custom utility functions from different modules.

2. Read the input data from the Excel file 'NetworkFlowProblem-Data.xlsx' and convert column names to lowercase. This is jusy to ensure that all column names matches with the ones in the code.

3. Define the 'delta' variable, which represents a tolerance for small floating-point discrepancies. This is to ensure that floating numbers after being imported from excel file, does not violate meeting the demands.

4. Define the processing steps in a list: ['Sourcing', 'Conditioning', 'Treatment', 'Forwarding', 'Delivery']. This is the ordinal list of all processes, and it is assumed that these steps should exist for all demands.

5. Define utility functions such as 'create_combined_dataframe', 'sort_formatted_out', 'write_output_into_excel', and 'subtract_amount_if_exists' to perform various data processing and output operations.

6. Sort the input data frame based on the 'week' column in descending order. This is just to speed up things as demands are more likely to happen at a later time, and it would be better to start from the latest demand.

7. Identify demands from the sorted data frame based on the last processing step ('Delivery').

8. Define the 'trace_back_demand_to_source' function to trace back each demand to its source based on the processing steps. It uses the 'used_resources' data frame to keep track of the resources used for each demand.

9. The 'trace_back_demand_to_source' function iterates over each demand and checks for the availability of resources to trace back the demand. It constructs a result with information about the demand and the traced-back resources for each processing step.

10. The script then creates a list of all combined data frames that store the trace back results for each demand.

11. The script enters a loop to randomly sample the demands and perform the trace back process until all demands can be successfully traced back or a limit of attempts is reached.

12. The output of the trace back is written into an Excel file named 'output.xlsx' in the root directory.

# Two-Stage Linear Programing (LP) Optimization Model

## How to run?

1. Change directory to "Two-Stage Optimizatio Model"
2. run optimization_v101.m in MATLAB

## Overview of algorithm

1. **Optimization Model (first stage):**

2. **Decision Variables:**

- Decision variavles, u, are continuous variables representing the capacities of the flows

3. **Constraints:**

- Upper bounds for the decision variables, u, are defined based on certain conditions such as the process order and feasible flows.
  Constraints cons_a2, cons_a3, and cons_a4 are formulated, defining the relationships between incoming and outgoing flows and ensuring the flow quantities match specified amounts.
- There's an additional penalty mechanism implemented, aiming to penalize non-negative values in u, although this part of the code is commented out.

3. **Objective Function:**

- The objective of the optimization model is to minimize the sum of all capacities (u).
  Solving the Problem:

- The optimization problem is solved using the linprog function, with specific options such as the maximum runtime. There are also options for intlinprog to penalize the number of edges (or flows) in the solution , but they are commented out.

4. **Ford-Fulkerson Algorithm (second stage):**

- The adjacency matrix is set based on the input x_sol_mod.
- The source and sink are identified based on the size of x_sol_mod.
- The Ford-Fulkerson algorithm is called, and the augmented paths are stored.

5. **Path and Flow Extraction:**

- The paths and flow values are extracted from the augmentedPaths obtained in the previous step. The paths and flows are saved in paths and - flows matrices, respectively.

6. **Traceback and Exhaustive Path Analysis:**

- A traceback analysis is performed on the paths and flows. This involves determining the individual delivery paths and flows.
- The code traces back through the paths, and the traced back deliveries are accumulated in traced_back_deliveries.
- The paths are then concatenated in reverse order, transforming and concatenating the data in a cell array format.
- A counter delivery_counter is used to label the deliveries, and the final result is accumulated in the output cell array.

# Additional Information

If you have questions, do not hesitate to reach out at shahryar.monghasemi@gmail.com
