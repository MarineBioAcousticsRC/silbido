% Fuzzy ART Neural Network Implementation.
% Version 1.0  02-Apr-2002
% Author:
%     Aaron Garrett
%     Jacksonville State University
%     Jacksonville, AL  36265
%
% Functions included in this directory:
%    ART_Activate_Categories - Performs the network category activation for a given input.
%    ART_Add_New_Category - Adds a new category element to the ART network.
%    ART_Calculate_Match - Calculates the degree of match between a given input and a category.
%    ART_Categorize - Uses a trained ART network to categorize a dataset.
%    ART_Complement_Code - Complement-codes the given input.   
%    ART_Create_Network - Creates the ART network.
%    ART_Learn - Trains a given ART network on a dataset.
%    ART_Update_Weights - Updates the weight matrix of the network.
%
% Description of the system architecture:
%    The above set of functions is used to create, train, and use an ART
%    network to categorize a dataset. While all of the functions are 
%    necessary, only half of them are meant to be called by the user. 
%    Those functions are as follows:
%
%    Functions available to user:
%        ART_Categorize
%        ART_Complement_Code   
%        ART_Create_Network
%        ART_Learn
%
%    The remaining four functions are used to modularize the structure
%    of the system. These functions are related to different components
%    of adaptive resonance theory.
%
%        ART_Activate_Categories essentially provides bottom-up activation
%        of the F2 layer for a given input. 
%
%        ART_Add_New_Category is used after a series of mismatch resets in
%        order to create a new F2 neuron to code the current input.
%
%        ART_Calculate_Match is used to determine the degree of match between
%        a given input and the category coded by the current F2 neuron.
%
%        ART_Update_Weights is used to update the weight matrix during learning
%        after resonance has been achieved.
%
% For an example of the use of these functions, see ARTExample.m in
% this directory.   
%
% Send comments to agarrett1@hotmail.com.
