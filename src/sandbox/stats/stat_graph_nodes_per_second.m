function [nodesPerSec] = stat_nodes_per_second(tonal, sourceGraph)
    nodeCount = sourceGraph.node_count();
    nodesPerSec = nodeCount / sourceGraph.graphLengthSeconds ;
end