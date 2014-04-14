function [accepted, selectedPath] = corpus_file_chooser(corpus_base)
    import javax.swing.*
    import javax.swing.tree.*;
    
    accepted = 0;
    selectedPath = '';
    
    f = figure('WindowStyle', 'modal', 'name', 'Select Audio File', 'NumberTitle','off');
    pos = get(f, 'Position');
    
    %treePanel = uipanel('Title','Main Panel','FontSize',12,...
    %         'BackgroundColor','white',...
    %         'Position',[0 .33 1 .67]);
    
    root = uitreenode('v0', corpus_base, 'Corups Root', [], false);
    [tree, container] = uitree('v0', 'Root', root, 'ExpandFcn', @myExpfcn, ...
                'SelectionChangeFcn', @selectionCallBack);
    
    % MousePressedCallback is not supported by the uitree, but by jtree
    jtree = handle(tree.getTree,'CallbackProperties');
    set(jtree, 'MousePressedCallback', @mousePressedCallback);
    function mousePressedCallback(hTree, eventData) %,additionalVar)
        if eventData.getClickCount==2 % how to detect double clicks
            if (isSelectionAudioFile())
                okCallback();
            end
        end
    end

    function result = isSelectionAudioFile() 
        nodes = tree.SelectedNodes;
        result = 0;
        if isempty(nodes)
            return;
        end

        node = nodes(1);
        if (~node.getAllowsChildren())
            result = 1;
        end
    end

    % left, bottom, width, height
    buttonPanelPos = [0, 0, pos(3), 50];
    height = pos(4) - buttonPanelPos(4);
    tree.Position = [0,buttonPanelPos(4),pos(3),height];
    
    buttonPanel = uipanel('Position', buttonPanelPos);
    buttonWidth = 50;
    buttonBottom = 10;
    buttonPadding = 20;
    
    % left, bottom, width, height
    okButtonPos = [pos(3) - buttonWidth - buttonPadding, buttonBottom, buttonWidth, 20];
    okButton = uicontrol('Style', 'pushbutton', 'String', 'Ok',...
        'Parent', buttonPanel, 'Position', okButtonPos,...
        'Callback', @okCallback);
    set(okButton,'Enable', 'off');
    
    % left, bottom, width, height
    cancelButtonPos = [pos(3) - ((buttonWidth + buttonPadding) * 2), buttonBottom, buttonWidth, 20];
    cancelButton = uicontrol('Style', 'pushbutton', 'String', 'Cancel',...
        'Parent', buttonPanel, 'Position', cancelButtonPos,...
        'Callback', @closeCallback);
     
    waitfor(f);
            
    function okCallback(hObject, eventdata)
        accepted = 1;
        close(f)
    end

    function closeCallback(hObject, eventdata)
        accepted = 0;
        close(f)
    end

    function selectionCallBack(tree, value)
        nodes = tree.SelectedNodes;
        if isempty(nodes)
            return
        end
        node = nodes(1);
        
        if (node.getAllowsChildren())
            set(okButton,'Enable', 'off');
            selectedPath = '';
        else
            set(okButton,'Enable', 'on');
            path = node.getPath();
            relPath = '';
            for idx = 2:length(path)
                aNode = path(idx);
                name = aNode.getName();
                relPath = strcat(relPath, filesep, char(name));
            end
        
            selectedPath = relPath;
        end
    end
end


function nodes = myExpfcn(tree, value)
    try
        count = 0;
        ch = dir(value);

        for i=1:length(ch)
            filename = ch(i).name;
            isdir = ch(i).isdir;
            
            [~,~,ext] = fileparts(filename);
            if ( any(strcmp(filename, {'.', '..', ''})) == 0 && ...
                 filename(1) ~= '.' &&  ...
                 (isdir || strcmp(ext, '.wav') ))
                count = count + 1;
                if ch(i).isdir
                    iconpath = [matlabroot, '/toolbox/matlab/icons/foldericon.gif'];
                else
                    iconpath = [matlabroot, '/toolbox/matlab/icons/pageicon.gif'];
                end
                nodes(count) = uitreenode([value, ch(i).name, filesep], ...
                    ch(i).name, iconpath, ~ch(i).isdir);
            end
        end
    catch
    end

    if (count == 0)
        nodes = [];
    end
end