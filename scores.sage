from sage.all import matrix

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
        # FIX: Reverted to the manual for loop for summation to ensure compatibility.
        out_degree = 0
        for x in A[v_idx]:
            out_degree += x

        size_second_neighborhood = 0
        for x in Npp_matrix[v_idx]:
            size_second_neighborhood += x
        
        diff = size_second_neighborhood - out_degree
        if diff > max_diff:
            max_diff = diff

    return float(-max_diff)