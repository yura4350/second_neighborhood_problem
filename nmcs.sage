from random import choice, random
from sage.all import matrix, vector, zero_matrix, ZZ

def add_source_or_sink_matrix(A):
    '''Adds a new vertex (as a source or sink) to an adjacency matrix A.'''
    n = A.nrows()
    if n == 0:
        return zero_matrix(ZZ, 1, 1) # Return a 1x1 zero matrix

    v_connect = choice(range(n))
    
    # Create a new (n+1)x(n+1) matrix
    A_new = zero_matrix(ZZ, n + 1, n + 1)
    A_new.submatrix(0, 0, A) # Copy old matrix into the top-left

    if random() < 0.5:
        # Add edge from new vertex n to v_connect (source)
        A_new[n, v_connect] = 1
    else:
        # Add edge from v_connect to new vertex n (sink)
        A_new[v_connect, n] = 1
    return A_new

def subdivide_edge_matrix(A):
    '''Subdivides a random edge in an adjacency matrix A.'''
    n = A.nrows()
    edges = A.nonzero_positions() # List of (row, col) tuples for all edges
    
    if not edges:
        return A

    u, v = choice(edges)
    
    # Create a new (n+1)x(n+1) matrix
    A_new = zero_matrix(ZZ, n + 1, n + 1)
    A_new.submatrix(0, 0, A)

    # Delete original edge and add two new ones via the new vertex n
    A_new[u, v] = 0
    A_new[u, n] = 1
    A_new[n, v] = 1
    return A_new

def add_edge_matrix(A):
    '''Adds a random non-existent, non-2-cycle edge to matrix A.'''
    n = A.nrows()
    potential_edges = []
    for r in range(n):
        for c in range(n):
            if r != c and A[r, c] == 0 and A[c, r] == 0:
                potential_edges.append((r, c))
    
    if potential_edges:
        r, c = choice(potential_edges)
        A_new = A.copy() # Important to copy before modification
        A_new[r, c] = 1
        return A_new
    return A

def NMCS_digraphs(current_matrix, depth, level, score_function, is_parent=True):
    '''The NMCS algorithm adapted for directed graph adjacency matrices.'''
    best_matrix = current_matrix
    best_score = score_function(current_matrix)

    if level == 0:
        next_matrix = current_matrix.copy()
        for _ in range(depth):
            r = random()
            if r < 0.4:
                next_matrix = add_source_or_sink_matrix(next_matrix)
            elif r < 0.8:
                next_matrix = subdivide_edge_matrix(next_matrix)
            else:
                next_matrix = add_edge_matrix(next_matrix)
                
        if score_function(next_matrix) > best_score:
            best_matrix = next_matrix
    else:
        # Recursively explore modifications
        modification_functions = [add_source_or_sink_matrix, subdivide_edge_matrix, add_edge_matrix]
        for mod_func in modification_functions:
            next_matrix = mod_func(current_matrix)
            if next_matrix is not current_matrix: # Check if a change was made
                res_matrix = NMCS_digraphs(next_matrix, depth, level - 1, score_function, False)
                res_score = score_function(res_matrix)
                if res_score > best_score:
                    best_matrix = res_matrix
                    best_score = res_score
                    if current_matrix.nrows() > 15 and is_parent:
                        break # Optimization
    return best_matrix