function [candidatesPerArea] = stat_graph_candidate_joins_per_area(tonal, sourceGraph)
    candidateCount = sourceGraph.candidateJoinCount;
    candidatesPerArea = candidateCount / (sourceGraph.graphLengthSeconds * sourceGraph.graphHeightFreq);
end