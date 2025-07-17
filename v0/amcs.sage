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

def AMCS(score_function, initial_graph=DiGraph([(i, (i+1)%10) for i in range(10)]), max_depth=10, max_level=10):
    '''The AMCS algorithm using adjacency matrix operations.'''
    current_matrix = initial_graph.adjacency_matrix()
    
    print("Best score (initial):", float(score_function(current_matrix)))

    depth = 0
    level = 1
    
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

        # Printing the adjacency matrix of the counterexample
        print("\nAdjacency Matrix of Counterexample:")
        print(current_matrix)

        final_graph = DiGraph(current_matrix)
        final_graph.show(edge_labels=False, layout="spring", title=f"Counterexample Found (Score: {final_score})")
    else:
        print(f"\nNo counterexample found. Best score: {final_score}")

        # Printing the best graph found after the search is exhausted
        final_graph = DiGraph(current_matrix)
        final_graph.show(edge_labels=False, layout="spring", title=f"Best graph (Score: {final_score})")
        
    return current_matrix

def main():
    start_time = time()
    AMCS(second_neighborhood_problem_score)
    print("Search time: %s seconds" % (time() - start_time))

if __name__ == "__main__":
    main()