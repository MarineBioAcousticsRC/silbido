function [junctionsPerArea] = stat_graph_junctions_per_area(tonal, sourceGraph)
    junctionCount = sourceGraph.junctionCount;
    junctionsPerArea = junctionCount / (sourceGraph.graphLengthSeconds * sourceGraph.graphHeightFreq);
end