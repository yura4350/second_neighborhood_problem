# Load the other two files first
load('scores.sage')
load('nmcs.sage')

# Necessary imports
from time import time
from random import choice, random
from sage.all import DiGraph, graphs, matrix

def create_random_oriented_graph(n, p):
    """Creates a random oriented G(n,p) graph."""
    G_undirected = graphs.RandomGNP(n, p)
    G_oriented = DiGraph()
    G_oriented.add_vertices(G_undirected.vertices())
    for u, v, _ in G_undirected.edges():
        if random() < 0.5:
            G_oriented.add_edge(u, v)
        else:
            G_oriented.add_edge(v, u)
    return G_oriented

def remove_low_degree_matrix(A):
    '''Removes a random vertex with total degree 1 from matrix A.'''
    n = A.nrows()
    if n == 0:
        return A
        
    low_degree_verts = []
    for i in range(n):
        in_degree = 0
        for r in range(n):
            in_degree += A[r, i]

        out_degree = 0
        for c in range(n):
            out_degree += A[i, c]

        if in_degree + out_degree == 1:
            low_degree_verts.append(i)
    
    if not low_degree_verts:
        return A

    v_to_remove = choice(low_degree_verts)
    indices = [i for i in range(n) if i != v_to_remove]
    return A.matrix_from_rows_and_columns(indices, indices)

def contract_path_matrix(A):
    '''Contracts a v with in=1, out=1 in matrix A.'''
    n = A.nrows()
    if n == 0:
        return A

    contractable = []
    for v in range(n):
        # FIX: Using the manual for loop for summation that is known to work.
        in_degree = 0
        for r in range(n):
            in_degree += A[r, v]

        out_degree = 0
        for c in range(n):
            out_degree += A[v, c]
            
        if in_degree == 1 and out_degree == 1:
            contractable.append(v)
    
    if not contractable:
        return remove_low_degree_matrix(A)

    v_contract = choice(contractable)
    
    try:
        predecessor = A[:, v_contract].nonzero_positions()[0][0]
        successor = A[v_contract, :].nonzero_positions()[0][0]
        
        A_new = matrix(A) 
        
        if predecessor != successor and A_new[predecessor, successor] == 0 and A_new[successor, predecessor] == 0:
            A_new[predecessor, successor] = 1
            
        indices = [i for i in range(n) if i != v_contract]
        return A_new.matrix_from_rows_and_columns(indices, indices)
    except IndexError:
        return A

def AMCS(score_function, initial_graph=DiGraph([(i, (i+1)%40) for i in range(40)]), max_depth=10, max_level=10):
    '''The AMCS algorithm using adjacency matrix operations.'''
    current_matrix = initial_graph.adjacency_matrix()
    
    print("Best score (initial):", float(score_function(current_matrix)))

    depth = 0
    level = 1
    min_order = 3
    
    while score_function(current_matrix) <= 0 and level <= max_level:
        next_matrix = matrix(current_matrix)
        
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

        # Printing the adjacency matrix of the counterexample
        print("\nAdjacency Matrix of Counterexample:")
        print(current_matrix)

        final_graph = DiGraph(current_matrix)
        final_graph.show(edge_labels=False, layout="spring", title=f"Counterexample Found (Score: {final_score})")
    else:
        print(f"\nNo counterexample found. Best score: {final_score}")
        final_graph = DiGraph(current_matrix)
        final_graph.show(edge_labels=False, layout="spring", title=f"Best graph (Score: {final_score})")
        
    return current_matrix

def main():
    start_time = time()
    AMCS(second_neighborhood_problem_score)
    print("Search time: %s seconds" % (time() - start_time))

if __name__ == "__main__":
    main()