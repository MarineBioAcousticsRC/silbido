function [candidatesPerNode] = stat_graph_candidate_joins_per_node(tonal, sourceGraph)
    candidateJoinCount = sourceGraph.candidateJoinCount;
    candidatesPerNode = candidateJoinCount / sourceGraph.node_count;
end