function [cyclesPerSecond] = stat_graph_cycles_per_second(tonal, sourceGraph)
    cycleCount = sourceGraph.avoidedCycleCount;
    cyclesPerSecond = cycleCount / sourceGraph.graphLengthSeconds;
end