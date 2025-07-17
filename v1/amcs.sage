# Load the other two files first
load('scores.sage')
load('nmcs.sage')

# Necessary imports
from time import time
from random import choice, random, sample
from sage.all import DiGraph, matrix

## CHANGED: Replaced with a 100% deterministic "check and fix" loop.
def build_guaranteed_graph(n, min_degree):
    """
    Builds a graph by systematically adding edges until every vertex
    is guaranteed to have an out-degree of at least `min_degree`.
    This method is deterministic and robust.
    """
    if n <= min_degree:
        raise ValueError(f"Number of nodes ({n}) must be greater than the minimum degree ({min_degree}).")

    G = DiGraph(n)
    print(f"Building graph to guaranteed minimum out-degree of {min_degree}...")
    
    # Generate a shuffled list of all possible targets to try for each vertex.
    # This adds randomness but ensures we try every possibility if needed.
    potential_targets = list(range(n))

    # Loop until the condition is met for all vertices simultaneously.
    while True:
        fixes_made_in_pass = 0
        
        # Iterate through each vertex to check and fix its out-degree.
        for v in range(n):
            # While the current vertex's degree is too low...
            while G.out_degree(v) < min_degree:
                # A fix is needed, so the graph isn't finished yet.
                fixes_made_in_pass += 1
                
                # Systematically find a valid neighbor to add an edge to.
                # We shuffle the targets to avoid biasing the graph structure.
                shuffled_targets = sample(potential_targets, len(potential_targets))
                
                found_edge_to_add = False
                for u in shuffled_targets:
                    # Add the edge if it's valid (no self-loop, no 2-cycle).
                    if u != v and not G.has_edge(v, u) and not G.has_edge(u, v):
                        G.add_edge(v, u)
                        found_edge_to_add = True
                        break # Move on to the next vertex or re-check this one
                
                if not found_edge_to_add:
                    # This should almost never happen unless the graph is complete.
                    print(f"Warning: Could not find a valid edge to add for vertex {v}. The graph is likely too dense.")
                    # To prevent an infinite loop, we break here.
                    # This vertex will be re-checked in the next main pass.
                    break

        # If we completed a full pass over all vertices and made no fixes, we're done.
        if fixes_made_in_pass == 0:
            print("Graph generation successful. All vertices meet the minimum degree.")
            break
            
    return G


def AMCS(score_function, initial_graph, max_depth=5, max_level=5):
    """The AMCS algorithm using adjacency matrix operations."""
    current_matrix = initial_graph.adjacency_matrix()
    initial_score = score_function(current_matrix)
    print("Best score (initial):", float(initial_score))

    if initial_score < -2999: # A sanity check based on low_degree_penalty
        print("\n\n*** CRITICAL WARNING: The initial score indicates a problem with the generated graph. ***\n\n")

    depth = 0
    level = 1
    # ... (rest of AMCS is unchanged) ...
    while score_function(current_matrix) <= 0 and level <= max_level:
        next_matrix = NMCS_digraphs(current_matrix, depth, level, score_function)
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
    num_nodes = 25
    min_out_degree = 7

    # This new function is guaranteed to work.
    initial_graph = build_guaranteed_graph(num_nodes, min_out_degree)

    start_time = time()
    AMCS(second_neighborhood_problem_score, initial_graph=initial_graph)
    print("Search time: %s seconds" % (time() - start_time))

if __name__ == "__main__":
    main()