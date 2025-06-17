from time import time
from random import choice, random
# Import Sage objects for graphs, matrices, and integer rings
from sage.all import DiGraph, graphs, zero_matrix, ZZ, copy

# Loads from the other SageMath files
load('scores.sage')
load('nmcs.sage')

def remove_low_degree_matrix(A):
    '''Removes a random vertex with total degree 1 from matrix A.'''
    n = A.nrows()
    in_degrees = [sum(A[:, c]) for c in range(n)]
    out_degrees = [sum(A[r, :]) for r in range(n)]
    
    low_degree_verts = [i for i in range(n) if in_degrees[i] + out_degrees[i] == 1]
    
    if not low_degree_verts:
        return A

    v_to_remove = choice(low_degree_verts)
    # Get indices for rows/cols to keep
    indices = [i for i in range(n) if i != v_to_remove]
    return A.matrix_from_rows_and_columns(indices, indices)

def contract_path_matrix(A):
    '''Contracts a v with in=1, out=1 in matrix A.'''
    n = A.nrows()
    in_degrees = [sum(A[:, c]) for c in range(n)]
    out_degrees = [sum(A[r, :]) for r in range(n)]
    
    contractable = [v for v in range(n) if in_degrees[v] == 1 and out_degrees[v] == 1]
    
    if not contractable:
        return remove_low_degree_matrix(A)

    v_contract = choice(contractable)
    
    try:
        # Find the single predecessor and successor
        predecessor = A[:, v_contract].nonzero_positions()[0][0]
        successor = A[v_contract, :].nonzero_positions()[0][0]
        
        A_new = A.copy()
        # Add edge from predecessor to successor if valid
        if predecessor != successor and A_new[predecessor, successor] == 0:
            A_new[predecessor, successor] = 1
            
        # Delete the contracted vertex
        indices = [i for i in range(n) if i != v_contract]
        return A_new.matrix_from_rows_and_columns(indices, indices)
    except IndexError:
        # Should not happen if degrees are correct, but as a safeguard
        return A

def AMCS(score_function, initial_graph=graphs.RandomGNP(10, 0.3).to_directed(), max_depth=5, max_level=3):
    '''The AMCS algorithm using adjacency matrix operations.'''
    
    # --- Start of the search with a matrix ---
    current_matrix = initial_graph.adjacency_matrix()
    
    print("Best score (initial):", float(score_function(current_matrix)))

    depth = 0
    level = 1
    min_order = 3
    
    while score_function(current_matrix) <= 0 and level <= max_level:
        next_matrix = current_matrix.copy()
        
        while next_matrix.nrows() > min_order:
            if random() < 0.7:
                if random() < 0.5:
                    next_matrix = remove_low_degree_matrix(next_matrix)
                else:
                    next_matrix = contract_path_matrix(next_matrix)
            else:
                break
        
        next_matrix = NMCS_digraphs(next_matrix, depth, level, score_function)
        
        current_score = score_function(current_matrix)
        next_score = score_function(next_matrix)
        
        print(f"Best score (lvl {level}, dpt {depth}):", float(max(next_score, current_score)))
        
        if next_score > current_score:
            current_matrix = next_matrix
            depth = 0
            level = 1
        elif depth < max_depth:
            depth += 1
        else:
            depth = 0
            level += 1
            
    final_score = score_function(current_matrix)
    if final_score > 0:
        print(f"\nCounterexample found! Score: {final_score}")
        # Convert the final matrix back to a DiGraph for plotting
        final_graph = DiGraph(current_matrix)
        final_graph.show(edge_labels=False, layout="spring", title=f"Counterexample Found (Score: {final_score})")
    else:
        print(f"\nNo counterexample found. Best score: {final_score}")
        
    return current_matrix

def main():
    start_time = time()
    AMCS(second_neighborhood_score)
    print("Search time: %s seconds" % (time() - start_time))

if __name__ == "__main__":
    main()