from sage.all import matrix

def second_neighborhood_problem_score(A):
    """
    Score based on a weighted penalty system.
    Heavily punishes vertices that fail the desired condition or have a low out-degree.
    """
    n = A.nrows()
    if n == 0:
        return -1

    # Define penalty constants at the top for easy tuning
    penalty_multiplier = 100  # For vertices that satisfy the conjecture
    sink_penalty = 5000       # For vertices with out-degree 0
    low_degree_penalty = 3000 # For vertices with out-degree 1-6

    A_squared = A * A
    A_reach_in_2 = matrix([[1 if x > 0 else 0 for x in row] for row in A_squared])
    Npp_matrix = A_reach_in_2 - A
    for i in range(n):
        Npp_matrix[i, i] = 0

    total_penalty = 0

    for v_idx in range(n):
        # Calculate the out-degree for the current vertex
        out_degree = sum(1 for x in A[v_idx] if x > 0)

        ## CHANGED: Added penalty logic for low out-degree
        # This new section checks the out-degree and applies a heavy penalty if it's too low.
        if out_degree == 0:
            # A sink is the worst case, apply the largest penalty
            total_penalty += sink_penalty
        elif out_degree <= 6:
            # A non-sink vertex with low degree is also heavily penalized
            total_penalty += low_degree_penalty

        # --- Original penalty logic for the conjecture condition ---
        size_second_neighborhood = sum(1 for x in Npp_matrix[v_idx] if x > 0)
        diff = size_second_neighborhood - out_degree

        if diff < 0:
            # This is a "good" vertex for a counterexample. Reduce the penalty slightly.
            total_penalty -= 1
        else:
            # This is a "bad" vertex. Add a penalty based on how far it is from violating the conjecture.
            # We add 1 to the difference so that even a diff of 0 gets a penalty.
            total_penalty += (diff + 1) * penalty_multiplier

    # NOTE: The old, separate loop for sink penalties has been removed
    # because the check is now efficiently handled inside the main loop above.

    # The search maximizes the score, so we return the negative of the total penalty.
    return float(-total_penalty)