# ==============================================================================
# run_search.sage (Complete Single-File Script)
# ==============================================================================

# All necessary imports for the entire script
from time import time
from random import choice, random
from sage.all import DiGraph, graphs, zero_matrix, ZZ, matrix

# ==============================================================================
# SCORES Function (from scores.sage)
# ==============================================================================
def second_neighborhood_score(A):
    """
    Calculates a score to find a counterexample to Seymour's Second Neighborhood Conjecture.
    """
    n = A.nrows()
    if n == 0:
        return -1

    A_squared = A * A
    A_reach_in_2 = matrix([[1 if x > 0 else 0 for x in row] for row in A_squared])
    Npp_matrix = A_reach_in_2 - A
    for i in range(n):
        Npp_matrix[i, i] = 0

    max_diff = -float('inf')

    for v_idx in range(n):
        out_degree = sum(A[v_idx])
        size_second_neighborhood = sum(Npp_matrix[v_idx])
        diff = size_second_neighborhood - out_degree
        if diff > max_diff:
            max_diff = diff

    return float(-max_diff)

# ==============================================================================
# NMCS Functions (from nmcs.sage)
# ==============================================================================
def add_source_or_sink_matrix(A):
    '''Adds a new vertex (as a source or sink) to an adjacency matrix A.'''
    n = A.nrows()
    if n == 0:
        return zero_matrix(ZZ, 1, 1)

    v_connect = choice(range(n))
    A_new = zero_matrix(ZZ, n + 1, n + 1)
    A_new[0:n, 0:n] = A

    if random() < 0.5:
        A_new[n, v_connect] = 1
    else:
        A_new[v_connect, n] = 1
    return A_new

def subdivide_edge_matrix(A):
    '''Subdivides a random edge in an adjacency matrix A.'''
    n = A.nrows()
    edges = A.nonzero_positions()
    
    if not edges:
        return A

    u, v = choice(edges)
    A_new = zero_matrix(ZZ, n + 1, n + 1)
    A_new[0:n, 0:n] = A

    A_new[u, v] = 0
    A_new[u, n] = 1
    A_new[n, v] = 1
    return A_new

def add_edge_matrix(A):
    '''Adds a random non-existent edge to matrix A.'''
    n = A.nrows()
    potential_edges = []
    
    for r in range(n):
        for c in range(n):
            if r != c and A[r, c] == 0 and A[c, r] == 0:
                potential_edges.append((r, c))
    
    if potential_edges:
        r, c = choice(potential_edges)
        A_new = matrix(A)
        A_new[r, c] = 1
        return A_new
        
    return A

def NMCS_digraphs(current_matrix, depth, level, score_function, is_parent=True):
    '''The NMCS algorithm for directed graph adjacency matrices.'''
    best_matrix = current_matrix
    best_score = score_function(current_matrix)

    if level == 0:
        next_matrix = matrix(current_matrix)
        for _ in range(depth):
            r = random()
            if r < 0.4: next_matrix = add_source_or_sink_matrix(next_matrix)
            elif r < 0.8: next_matrix = subdivide_edge_matrix(next_matrix)
            else: next_matrix = add_edge_matrix(next_matrix)
                
        if score_function(next_matrix) > best_score:
            best_matrix = next_matrix
    else:
        modification_functions = [add_source_or_sink_matrix, subdivide_edge_matrix, add_edge_matrix]
        for mod_func in modification_functions:
            next_matrix_candidate = mod_func(current_matrix)
            
            if next_matrix_candidate is not current_matrix:
                res_matrix = NMCS_digraphs(next_matrix_candidate, depth, level - 1, score_function, False)
                res_score = score_function(res_matrix)
                
                if res_score > best_score:
                    best_matrix = res_matrix
                    best_score = res_score
                    if current_matrix.nrows() > 15 and is_parent:
                        break
                        
    return best_matrix

# ==============================================================================
# AMCS Algorithm and Main Execution (from amcs.sage)
# ==============================================================================
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

# Copy this entire function and paste it into your single_search.sage file

def remove_low_degree_matrix(A):
    '''Removes a random vertex with total degree 1 from matrix A.'''
    n = A.nrows()
    if n == 0:
        return A
        
    low_degree_verts = []
    for i in range(n):
        # THE FINAL, MOST BASIC FIX: Manually sum the elements with a for loop.
        # This has no special method dependencies.
        
        in_degree = 0
        for r in range(n):
            in_degree += A[r, i]

        out_degree = 0
        for c in range(n):
            out_degree += A[i, c]
        
        # This adds two integers and will work.
        if in_degree + out_degree == 1:
            low_degree_verts.append(i)
    
    if not low_degree_verts:
        return A

    v_to_remove = choice(low_degree_verts)
    indices = [i for i in range(n) if i != v_to_remove]
    return A.matrix_from_rows_and_columns(indices, indices)

# Also ensure this function is correct in your single_search.sage file

# In your single_search.sage file

def contract_path_matrix(A):
    '''Contracts a v with in=1, out=1 in matrix A.'''
    n = A.nrows()
    if n == 0:
        return A

    contractable = []
    for v in range(n):
        # Apply the same manual summation fix here.
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


def AMCS(score_function, initial_graph=create_random_oriented_graph(10, 0.3), max_depth=5, max_level=3):
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
        final_graph = DiGraph(current_matrix)
        final_graph.show(edge_labels=False, layout="spring", title=f"Counterexample Found (Score: {final_score})")
    else:
        print(f"\nNo counterexample found. Best score: {final_score}")
        
    return current_matrix

def main():
    start_time = time()
    # All functions are now in this file, so we just call them directly.
    AMCS(second_neighborhood_score)
    print("Search time: %s seconds" % (time() - start_time))

if __name__ == "__main__":
    main()