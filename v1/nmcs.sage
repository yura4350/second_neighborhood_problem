from random import choice, random
from sage.all import zero_matrix, ZZ, matrix

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

def rewire_edge_matrix(A):
    '''
    Removes a random existing edge and adds a random non-existent edge.
    This operation preserves the number of vertices and edges.
    '''
    n = A.nrows()
    existing_edges = A.nonzero_positions()
    
    # Return if there are no edges to remove
    if not existing_edges:
        return A

    # Choose a random edge to remove
    u_rem, v_rem = choice(existing_edges)
    
    # Find potential new edges (where no edge exists in either direction)
    potential_new_edges = []
    for r in range(n):
        for c in range(n):
            # A new edge can't be a self-loop, and can't already exist in either direction
            if r != c and A[r, c] == 0 and A[c, r] == 0:
                potential_new_edges.append((r, c))

    # Return if there's nowhere to add a new edge
    if not potential_new_edges:
        return A

    # Choose a random new edge to add
    u_add, v_add = choice(potential_new_edges)

    # Create a new matrix with the changes
    A_new = matrix(A)
    A_new[u_rem, v_rem] = 0
    A_new[u_add, v_add] = 1
    
    return A_new

def NMCS_digraphs(current_matrix, depth, level, score_function, is_parent=True):
    '''The NMCS algorithm for directed graph adjacency matrices.'''
    best_matrix = current_matrix
    best_score = score_function(current_matrix)

    if level == 0:
        next_matrix = matrix(current_matrix)
        for _ in range(depth):
            r = random()
            # Probabilities are adjusted to include the new function
            if r < 0.25: next_matrix = add_source_or_sink_matrix(next_matrix)
            elif r < 0.5: next_matrix = subdivide_edge_matrix(next_matrix)
            elif r < 0.75: next_matrix = add_edge_matrix(next_matrix)
            else: next_matrix = rewire_edge_matrix(next_matrix)
                
        if score_function(next_matrix) > best_score:
            best_matrix = next_matrix
    else:
        # The new rewire function is added to the list of modifications
        modification_functions = [add_source_or_sink_matrix, subdivide_edge_matrix, add_edge_matrix, rewire_edge_matrix]
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