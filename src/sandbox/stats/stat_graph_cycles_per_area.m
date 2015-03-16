function [cyclesPerSecond] = stat_graph_cycles_per_area(tonal, sourceGraph)
    cycleCount = sourceGraph.avoidedCycleCount;
    cyclesPerSecond = cycleCount / (sourceGraph.graphLengthSeconds * sourceGraph.graphHeightFreq);
end