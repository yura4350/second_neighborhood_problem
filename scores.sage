from sage.all import matrix

def second_neighborhood_problem_score(A):
    """
    Score based on a weighted penalty system.
    Heavily punishes vertices that fail the desired condition, creating a strong gradient.
    """
    n = A.nrows()
    if n == 0:
        return -1

    A_squared = A * A
    A_reach_in_2 = matrix([[1 if x > 0 else 0 for x in row] for row in A_squared])
    Npp_matrix = A_reach_in_2 - A
    for i in range(n):
        Npp_matrix[i, i] = 0

    # Accumulates the total "penalty" of the graph. Our goal is to minimize it.
    total_penalty = 0
    penalty_multiplier = 100  # A vertex that fails is 100x worse than a vertex that succeeds. This parameter can be tuned - noticed, that works bad for lower values

    for v_idx in range(n):
 
        out_degree = 0
        out_degree = sum(1 for x in A[v_idx] if x > 0)

        size_second_neighborhood = 0
        size_second_neighborhood = sum(1 for x in Npp_matrix[v_idx] if x > 0)
        
        diff = size_second_neighborhood - out_degree

        # Apply the penalty logic
        if diff < 0:
            # This is a "good" vertex. Its difference is negative.
            # Adding it to the penalty makes the total penalty lower (better).

            # 1st option suggested (In this case large penalty multiplier to be used to offset how good of a counter-vetix the vertix is)
            # total_penalty += diff

            # 2nd option suggested (but we also should somehow care about how 'good' of a vertix a good vertix is
            total_penalty -= 1

            # 3rd option - no reward to actually find a counterexample?
            # pass

        else:
            # This is a "bad" vertex. Its difference is 0 or positive.
            # We add its difference to the penalty, multiplied by the penalty factor.
            # We add 1 to the difference so that even a difference of 0 gets a penalty.
            total_penalty += (diff + 1) * penalty_multiplier
    
    """
    IMPORTANT: Graphs with sinks automatically satisfy second neighborhood problem and create local minima.
    Hence, we largely penalize sinks in O(n * m) - same time complexity as done before, so really no influence
    """

    sink_penalty = 5000  # A large, fixed penalty for each sink found.
    
    for i in range(n):
        # Check if vertex i is a sink (its out-degree is 0).
        # We use the manual for loop for summation to ensure compatibility.
        row_sum = 0
        for x in A[i, :]:
            row_sum += x
        
        if row_sum == 0:
            # If it's a sink, add the large penalty to this graph's total penalty.
            total_penalty += sink_penalty

    # The search tries to maximize the score, so we return the negative of the penalty.
    # A lower penalty results in a higher score.
    return float(-total_penalty)