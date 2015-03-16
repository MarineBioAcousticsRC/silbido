function [junctionsPerSecond] = stat_graph_junctions_per_second(tonal, sourceGraph)
    junctionCount = sourceGraph.junctionCount;
    junctionsPerSecond = junctionCount / sourceGraph.graphLengthSeconds;
end