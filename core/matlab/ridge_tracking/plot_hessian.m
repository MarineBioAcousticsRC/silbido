% Load a spectrogram.
load exampleridge


%% Plot parameteriztion
show_spetrogram = true;
bright_dB = 0;
contrast_Pct = 75;

show_gradient_vectors = true;
gv_color = 'g';

show_eigen_vectors = true;
scale_eignen_vectors = true;
ev_color = 'c';

show_contours = true;
contour_color = 'y';

show_ridges = true;
ridge_line_spec = 'r';

%% Derivative Calculation
dims = size(I);

K=4;
gx=gfilter(I,K,[0 1]);
gy=gfilter(I,K,[1 0]);
gxx=gfilter(I,K,[0 2]);
gyy=gfilter(I,K,[2 0]);
gxy=gfilter(I,K,[2 2]);
gyx=gxy;


figure('Name', 'Ridge Detection');
axis();
axis off
hold on;

%% Spectrogram
if (show_spetrogram)
    image_h = imagesc(I);
    set(gca,'YDir','normal');
    colormap(gray);
      
    colorData = (contrast_Pct/100) .* I + bright_dB;
    set(image_h, 'CData', colorData);
    
end



%% Contours
if (show_contours)
    contour(I,contour_color);
end


%% Gradient and Hessian Calculation
step=5;
x_steps=1:step:size(I,2);
y_steps=1:step:size(I,1);
[X,Y]=meshgrid(x_steps,y_steps);


% Create containers to hold the gradient vectors and dominant
% Eigen vectors of the Hessian matrix.
gv_x = ones(dims) * NaN;
gv_y = ones(dims) * NaN;

ev_x = ones(dims) * NaN;
ev_y = ones(dims) * NaN;

% For each selected point in the x and y calculate the gv and
% ev.
for idx_x = 1:length(x_steps)
    for idx_y = 1:length(y_steps)
        x = x_steps(idx_x);
        y = y_steps(idx_y);

        % Set up the gradient vector
        gv = [gx(y,x); gy(y,x)];

        % Set up the Hessian matrix
        H = [gxx(y,x) gxy(y,x); gyx(y,x) gyy(y,x)];

        % Find the dominant eigenvector of the Hessian matrix
        [V, E] = eig(H);
        if abs(E(1,1)) > abs(E(2,2))
            ev = V(:,1);
        else
            ev = V(:,2);
        end  

        gv_x(y, x) = gv(1);
        gv_y(y, x) = gv(2);

        if (scale_eignen_vectors)
            % The gv and ev can have vastly different magnitudes.
            % While less accurate, it is more visually inuitive to
            % scale the ev to the same length as the gv.
            gv_mag = norm([gv_x(y,x) gv_y(y,x)]);
            scaling = gv_mag / norm(ev);
            ev = ev * abs(scaling);
        end

        ev_x(y, x) = ev(1);
        ev_y(y, x) = ev(2);
    end        
end

 %% Gradient Vector
 if (show_gradient_vectors)
     GV_X = gv_x(y_steps,x_steps);
     GV_Y = gv_y(y_steps,x_steps);
     quiver(X(:),Y(:),GV_X(:),GV_Y(:), gv_color);
 end

%% Hessian Eigen Vector
if (show_eigen_vectors)
    EV_X = ev_x(y_steps,x_steps);
    EV_Y = ev_y(y_steps,x_steps);
    quiver(X(:),Y(:),EV_X(:),EV_Y(:), ev_color);
end

%% Ridges       
if (show_ridges)
    [TT,A]=CalculateFunctionalsAndTrackNew(I,K,zeros(size(I)),5);
    for n=1:length(TT)
        T=TT{n};
        plot(T(:,1),T(:,2),ridge_line_spec,'LineWidth',3);
    end
end

hold off