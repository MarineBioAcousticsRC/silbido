function [nodesPerArea] = stat_nodes_per_area(tonal, sourceGraph)
    nodeCount = sourceGraph.node_count();
    nodesPerArea = nodeCount / (sourceGraph.graphLengthSeconds * sourceGraph.graphHeightFreq);
end