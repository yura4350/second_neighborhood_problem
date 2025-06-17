def second_neighborhood_score(A):
    """
    Calculates the score for the Second Neighborhood Problem from an adjacency matrix.

    The conjecture states that in any oriented graph, there is a vertex v
    such that |N++(v)| >= d+(v). A positive score indicates a counterexample.

    Score = max(d+(v) - |N++(v)|) over all vertices v.

    Args:
        A: The adjacency matrix of the oriented graph.
    
    Returns:
        A float representing the largest violation of the conjecture found.
    """
    n = A.nrows()
    if n == 0:
        return -1  # Undefined for an empty graph

    # A_squared gives the number of paths of length 2.
    A_squared = A * A

    # Tracks the largest violation found.
    max_violation = -float('inf')

    for v_idx in range(n):
        # Out-degree is the sum of the v-th row.
        out_degree = sum(A[v_idx])

        # N+(v): columns j where A[v_idx, j] is 1.
        first_neighborhood = {j for j, val in enumerate(A[v_idx]) if val == 1}

        # Vertices reachable in 2 steps: columns k where A_squared[v_idx, k] > 0.
        two_step_reachable = {k for k, val in enumerate(A_squared[v_idx]) if val > 0}
        
        # N++(v): vertices at distance *exactly* 2.
        # Remove vertices from the first neighborhood and the vertex v itself.
        second_neighborhood = two_step_reachable - first_neighborhood
        if v_idx in second_neighborhood:
            second_neighborhood.remove(v_idx)
            
        size_second_neighborhood = len(second_neighborhood)
        
        # Calculate the violation for this vertex.
        violation = out_degree - size_second_neighborhood
        if violation > max_violation:
            max_violation = violation

    # The score is positive only if a counterexample exists.
    return float(max_violation)