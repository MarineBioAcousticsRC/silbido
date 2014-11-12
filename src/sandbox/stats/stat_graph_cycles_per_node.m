function [cyclesPerNode] = stat_graph_cycles_per_node(tonal, sourceGraph)
    cycleCount = sourceGraph.avoidedCycleCount;
    cyclesPerNode = cycleCount / sourceGraph.node_count();
end