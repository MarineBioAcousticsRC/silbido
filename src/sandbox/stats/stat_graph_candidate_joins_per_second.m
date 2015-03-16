function [candidatesPerSecond] = stat_graph_candidate_joins_per_second(tonal, sourceGraph)
    candidateJoinCount = sourceGraph.candidateJoinCount;
    candidatesPerSecond = candidateJoinCount / sourceGraph.graphLengthSeconds;
end