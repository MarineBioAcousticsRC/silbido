function utLatexMatrix(fid, Matrix, ElementFormat)
% utLatexMatrix(FileId, Matrix, ElementFormatString)
%	Generates LaTeX code for Matrix.
%	FileId - file descriptor, result of fopen or 1 for stdout
%	Matrix - matrix to be writtien to FileId
%	ElementFormatString - Optional string indicating element
%		type.  Any valid fprintf() string is acceptable.
%		Defaults to '%f'

% check arguments
error(nargchk(2, 3, nargin))

if nargin < 3
  ElementFormat = '%f'
end

[Rows Cols] = size(Matrix);

fprintf(fid, '\\left|\n');
fprintf(fid, sprintf('\\\\begin{array}{%s}\n', setstr(ones(1,Cols)*'r')));
for r = 1:Rows
  for c = 1:Cols
    fprintf(fid, sprintf(ElementFormat, Matrix(r,c)));
    if c == Cols
      if r == Rows
	fprintf(fid, '\n');
      else
	fprintf(fid, '\\\\\n');
      end
    else
      fprintf(fid, '&\t');
    end
  end
end
fprintf(fid, '\\end{array}\n');
fprintf(fid, '\\right|\n');

