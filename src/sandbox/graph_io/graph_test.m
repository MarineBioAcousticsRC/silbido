import tonals.*;
base_dir = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/';
file = 'bottlenose/palmyra092007FS192-070924-205305.graph';

graphs = GraphIO.loadGraphs([base_dir file]);

graph1 = graphs.get(6);

graph1.getGraphId()