function [junctionsPerNode] = stat_graph_junctions_per_node(tonal, sourceGraph)
    junctionCount = sourceGraph.junctionCount;
    junctionsPerNode = junctionCount / sourceGraph.node_count();
end