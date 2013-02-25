function utWriteTextMatrix(Filename, Matrix)
% utWriteTextMatrix(Filename, Matrix)
% Save the contents of Matrix in Filename as a text file.
% Entries of matrices are tab separated
% The more compact of decimal & exponential notation is used for each entry.

seperator = ' ';       % change for different separator, e.g. \t
handle = fopen(Filename, 'w');
[rows, cols] = size(Matrix);
for row=1:rows
  % first column special, no leading separator
  fprintf(handle, '%e', Matrix(row, 1));
  for col=2:cols
    fprintf(handle, '%s%e', seperator, Matrix(row, 1));
  end
  fprintf(handle, '\n');
end
fclose(handle);
