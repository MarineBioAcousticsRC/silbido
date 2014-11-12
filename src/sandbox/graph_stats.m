addpath('/Users/michael/development/silbido/matlab-src/utils');


base_dir = '/Users/michael/development/silbido/silbido-hg-repo/src/sandbox/testing/results';

graphs = utFindFiles({'*.graph'}, base_dir, true);

gCandidateJoinCounts = [];
gCandidatesPerSecond = [];
gCandidatesPerNode = [];

gJunctionCounts = [];
gJunctionsPerSecond = [];
gJunctionsPerNode = [];

gCycleCounts = [];
gCylesPerSecond = [];
gCylesPerNode = [];


bCandidateJoinCounts = [];
bCandidatesPerSecond = [];
bCandidatesPerNode = [];


bJunctionCounts = [];
bJunctionsPerSecond = [];
bJunctionsPerNode = [];

bCycleCounts = [];
bCylesPerSecond = [];
bCylesPerNode = [];

for graphIdx = 1:size(graphs,1)
    graph_file = graphs{graphIdx};
    [path, name, ~] = fileparts(graph_file);
    %rel_path = path(size(base_dir,2)+1:end);
    good_detections = [fullfile(path, name) '_a.d+'];
    bad_detections = [fullfile(path, name) '.d-'];
    
    graphsMap = tonals.GraphIO.loadGraphsAsMap(graph_file);
    
    goodTonals = dtTonalsLoad(good_detections, 0);
    for tonalIdx = 0:(goodTonals.size() - 1)
        tonal = goodTonals.get(tonalIdx);
        graphId = tonal.getGraphId();
        sourceGraph = graphsMap.get(java.lang.Long(graphId));
        
          % Candidate Joins
        candidateJoinCount = sourceGraph.candidateJoinCount;
        gCandidateJoinCounts = [gCandidateJoinCounts candidateJoinCount];
        
        candidatesPerSecond = candidateJoinCount / sourceGraph.graphLengthSeconds;
        gCandidatesPerSecond = [gCandidatesPerSecond candidatesPerSecond];
        
        candidatesPerNode = candidateJoinCount / sourceGraph.node_count();
        gCandidatesPerNode = [gCandidatesPerNode candidatesPerNode];
        
        
        
        
        % Junctions
        junctionCount = sourceGraph.junctionCount;
        gJunctionCounts = [gJunctionCounts junctionCount];
        
        junctionsPerSecond = junctionCount / sourceGraph.graphLengthSeconds;
        gJunctionsPerSecond = [gJunctionsPerSecond junctionsPerSecond];
        
        junctionsPerNode = junctionCount / sourceGraph.node_count();
        gJunctionsPerNode = [gJunctionsPerNode junctionsPerNode];
        
        
        % Avoided Cycles
        cycleCount = sourceGraph.avoidedCycleCount;
        gCycleCounts = [gCycleCounts cycleCount];
        
        cylesPerSecond = cycleCount / sourceGraph.graphLengthSeconds;
        gCylesPerSecond = [gCylesPerSecond cylesPerSecond];
        
        cylesPerNode = cycleCount / sourceGraph.node_count();
        gCylesPerNode = [gCylesPerNode cylesPerNode];
    end
    
    
    badTonals = dtTonalsLoad(bad_detections, 0);
    for tonalIdx = 0:(badTonals.size() - 1)
        tonal = badTonals.get(tonalIdx);
        graphId = tonal.getGraphId();
        sourceGraph = graphsMap.get(java.lang.Long(graphId));
        
        % Candidate Joins
        candidateJoinCount = sourceGraph.candidateJoinCount;
        bCandidateJoinCounts = [bCandidateJoinCounts candidateJoinCount];
        
        candidatesPerSecond = candidateJoinCount / sourceGraph.graphLengthSeconds;
        bCandidatesPerSecond = [bCandidatesPerSecond candidatesPerSecond];
        
        candidatesPerNode = candidateJoinCount / sourceGraph.node_count();
        bCandidatesPerNode = [bCandidatesPerNode candidatesPerNode];
        
        
        % Junctions
        junctionCount = sourceGraph.junctionCount;
        bJunctionCounts = [bJunctionCounts junctionCount];
        
        junctionsPerSecond = junctionCount / sourceGraph.graphLengthSeconds;
        bJunctionsPerSecond = [bJunctionsPerSecond junctionsPerSecond];
        
        junctionsPerNode = junctionCount / sourceGraph.node_count();
        bJunctionsPerNode = [bJunctionsPerNode junctionsPerNode];
        
        
        % Avoided Cycles
        cycleCount = sourceGraph.avoidedCycleCount;
        bCycleCounts = [bCycleCounts cycleCount];
        
        cylesPerSecond = cycleCount / sourceGraph.graphLengthSeconds;
        bCylesPerSecond = [bCylesPerSecond cylesPerSecond];
        
        cylesPerNode = cycleCount / sourceGraph.node_count();
        bCylesPerNode = [bCylesPerNode cylesPerNode];
    end
end


if (false)

% Cycles
stHistogramCompare(bCycleCounts, gCycleCounts, 'Bins', 50); % Not great
stHistogramCompare(bCylesPerNode, gCylesPerNode, 'Bins', 50); % Not great
stHistogramCompare(bCylesPerSecond, gCylesPerSecond, 'Bins', 50); % Greater than 1500

% Junctions
stHistogramCompare(bJunctionCounts, gJunctionCounts, 'Bins', 50); % Not great
stHistogramCompare(bJunctionsPerSecond, gJunctionsPerSecond, 'Bins', 50); % Not great
stHistogramCompare(bJunctionsPerNode, gJunctionsPerNode, 'Bins', 50); % Not great

% Candidate Joins
stHistogramCompare(bCandidateJoinCounts, gCandidateJoinCounts, 'Bins', 50); %not great
stHistogramCompare(bCandidatesPerSecond, gCandidatesPerSecond, 'Bins', 50); % Good after 1750
stHistogramCompare(bCandidatesPerNode, gCandidatesPerNode, 'Bins', 50); % Not Great
end

% Candidates Per Second