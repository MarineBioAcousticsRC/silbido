function varargout = RidgeAdjuster(varargin)
% RIDGEADJUSTER MATLAB code for RidgeAdjuster.fig
%      RIDGEADJUSTER, by itself, creates a new RIDGEADJUSTER or raises the existing
%      singleton*.
%
%      H = RIDGEADJUSTER returns the handle to a new RIDGEADJUSTER or the handle to
%      the existing singleton*.
%
%      RIDGEADJUSTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RIDGEADJUSTER.M with the given input arguments.
%
%      RIDGEADJUSTER('Property','Value',...) creates a new RIDGEADJUSTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RidgeAdjuster_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RidgeAdjuster_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RidgeAdjuster

% Last Modified by GUIDE v2.5 29-Nov-2012 16:04:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @RidgeAdjuster_OpeningFcn, ...
    'gui_OutputFcn',  @RidgeAdjuster_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before RidgeAdjuster is made visible.
function RidgeAdjuster_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RidgeAdjuster (see VARARGIN)

% Choose default command line output for RidgeAdjuster
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RidgeAdjuster wait for user response (see UIRESUME)
% uiwait(handles.figure1);

global PathName hh

PathName='.';

set(handles.pushbuttonPrev,'enable','off');
set(handles.pushbuttonNext,'enable','off');
set(handles.pushbuttonRevert,'enable','off');

global axesHandle sel
axesHandle=handles.axes1;
set(handles.figure1,'WindowButtonUpFcn',@ButtonUp);
sel=0;


function ButtonUp(handle,b,c)

global axesHandle I R sel T F

pt=get(axesHandle,'CurrentPoint');
pt=pt(1,:);
s=get(handle,'SelectionType');

switch s(1)
    case 'n'
        type=1;
    case 'a'
        type=2;
    case 'e'
        type=3;
end

x=pt(1);
y=pt(2);

[c,d]=FindNearestRidge(x,y);

THRESH=10;
if d<THRESH
    % clicked close to a ridge
    if c~=sel
        % clicked close to a non-selected ridge
        
        switch type
            case 1 % left button
                % select the ridge
                sel=c;
                Display(I,R,T,F);
                SelectRidge(R{sel});
            case 2 % right button
                % merge ridges
                MergeRidges(sel,c);
            case 3 % middle button
        end
    else
        % clicked on the selected ridge
        switch type
            case 1
                % keep only to the left of the click
                KeepLeft(x,y);
            case 2
                KeepRight(x,y);
            case 3
                SplitRidge(x,y);
        end
    end
else
    % clicked far from a ridge
    switch type
        case 1 % left button
            % deselect the ridge
            sel=0;
            Display(I,R,T,F);
        case 2 % right button
        case 3 % middle button
    end
end


% --- Outputs from this function are returned to the command line.
function varargout = RidgeAdjuster_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonPrev.
function pushbuttonPrev_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPrev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


global currentFile

SaveCurrent;
currentFile=currentFile-1;
LoadAndDisplayFile(handles);


% --- Executes on button press in pushbuttonNext.
function pushbuttonNext_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonNext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global currentFile

SaveCurrent;
currentFile=currentFile+1;
LoadAndDisplayFile(handles);

% --- Executes on button press in pushbuttonRevert.
function pushbuttonRevert_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRevert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

LoadAndDisplayFile(handles);

% --- Executes on button press in pushbuttonOpen.
function pushbuttonOpen_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global FN currentFile PathName

[FileName,PathName] = uigetfile([PathName '.mat'],'Open matlab directory...');
if ~isempty(FileName) && length(FileName)>1
    FN=dir([PathName '/*.mat']);
    currentFile=1;
    if isempty(dir([PathName '/adjustedR']))
        mkdir([PathName '/adjustedR']);
    end
    LoadAndDisplayFile(handles);
    set(handles.pushbuttonRevert,'enable','on');
end



function LoadAndDisplayFile(handles)

global FN currentFile PathName I R T F

load([PathName '/' FN(currentFile).name]);

Display(I,R,T,F);

if currentFile==1
    set(handles.pushbuttonPrev,'enable','off');
else
    set(handles.pushbuttonPrev,'enable','on');
end
if currentFile==length(FN)
    set(handles.pushbuttonNext,'enable','off');
else
    set(handles.pushbuttonNext,'enable','on');
end


function Display(I,R,T,F)

iptsetpref('ImshowAxesVisible','on');
hold off
imagesc(I,'XData',[T(1) T(end)],'YData',[-max(F) 0]);
colormap(gray)

% imshow(I,[]);

cc='gbcmy';
hold on
for n=1:length(R)
    r=R{n};
    plot(r(:,1),r(:,2),cc(mod(n,length(cc))+1),'LineWidth',2);
end
hold off



function SelectRidge(r)
hold on
plot(r(:,1),r(:,2),'r','LineWidth',3);
hold off


function SaveCurrent

global PathName FN R currentFile I T F

save([PathName '/adjustedR/' FN(currentFile).name '-R.mat'],'R','I','T','F');


function [c,d]=FindNearestRidge(x,y)

global R T F

if x<min(T) || x>max(T) || -y<min(F) || -y>max(F)
    c=NaN;
    d=Inf;
    return;
end

m=ones(length(R),1)*Inf;
for n=1:length(R)
    [~,z]=FindClosestPixel(R{n},[x y]);
    m(n)=z;
end

[d,c]=min(m);


function MergeRidges(a,b)

global sel I R T F

r=sortrows([R{a};R{b}]);
msel=min(a,b);
xsel=max(a,b);
R{msel}=r;
R(xsel)=[];
sel=msel;
Display(I,R,T,F);
SelectRidge(R{sel});

function KeepLeft(x,y)

global R sel I T F

r=R{sel};
c=FindClosestPixel(r,[x y]);
r=r(1:c,:);
R{sel}=r;
Display(I,R,T,F);
SelectRidge(R{sel});

function [c,z]=FindClosestPixel(r,q)

global T F

r=ConvertSpectralCoordsToPixels({r},T,F);
r=r{1};
q=ConvertSpectralCoordsToPixels({q},T,F);
q=q{1};
d=sqrt(sum((r-repmat(q,size(r,1),1)).^2,2));
[z,c]=min(d);


function KeepRight(x,y)

global R sel I T F

r=R{sel};
c=FindClosestPixel(r,[x y]);
r=r(c:end,:);
R{sel}=r;
Display(I,R,T,F);
SelectRidge(R{sel});

function SplitRidge(x,y)

global R sel I T F

r=R{sel};
c=FindClosestPixel(r,[x y]);
r1=r(1:c,:);
r2=r(c+1:end,:);
R{sel}=r1;
R{length(R)+1}=r2;
Display(I,R,T,F);
SelectRidge(R{sel});


% --- Executes on button press in pushbuttonZoom.
function pushbuttonZoom_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonZoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global I R T F

rect0=getrect;
srect=[[rect0(1);rect0(1)+rect0(3)] [rect0(2);rect0(2)+rect0(4)]];
rpix=ConvertSpectralCoordsToPixels({srect},T,F);
rect=rpix{1};

I2=I(round(rect(1,2):rect(2,2)),round(rect(1,1):rect(2,1)));
R2=Process(I2);
i=length(R);
for j=1:length(R2)
    i=i+1;
    r=R2{j};
    r=r+repmat([rect(1) rect(3)],size(r,1),1);
    r=ConvertPixelsToSpectralCoords({r},T,F);
    R{i}=r{1};
end
Display(I,R,T,F);

function R=Process(I)

pad=10;
isd=1;
K=1;
minLen=5;
maxGap=20;
terminalSmoothing=100;
maxTurn=25;

I=padarray(I,[pad pad],mean(I(:)));
I = bpass(I,1,10);
I=I(pad+1:end-pad,pad+1:end-pad);
mask=MakeMask2(I,isd);
I(find(mask))=0;

TT=CalculateFunctionalsAndTrackNew(I,K,mask,minLen,0,0,0);
R=TrackCurves(TT,1,I,maxGap,terminalSmoothing,minLen,maxTurn);


function DeleteRidge

global I R sel T F

R(sel)=[];

Display(I,R,T,F);

% --- Executes on key release with focus on figure1 and none of its controls.
function figure1_KeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)

global sel

k=eventdata.Key;

if strcmp(k,'delete') & sel~=0
    DeleteRidge;
end




% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SaveCurrent;
