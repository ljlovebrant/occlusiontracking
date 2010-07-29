function [ handles ] = adjustGUIandAxeses(hObject, no_axes, handles)
% hObject needs to be the GUI figure

top_ui_height = 0;
border_pxls = 20;
aspect_ratio_to_maintain = 1.333;
min_gap = 10;
gui_starting_pos = [ 40 100 ];

            %Axes Axes_rows Axes_cols Gui_Width Gui_Height
layouts = [ 1     1         1         850       650;        % for 1 axes
            2     1         2        1100       550;        % for 2 axes
            4     2         2         850       750;        % for 4 axes
            6     2         3        1200       750 ];      % for 6 axes

% delete all old axes handles
axes_h = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re)';
% remove handles
for h = axes_h
    handles = rmfield(handles, get(h,'Tag'));
end
% add uicontextmenu handles
axes_h = [axes_h findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_uicontext_menu_re)'];
recursiveHandleDelete(axes_h);

set(handles.roc_gui, 'Units', 'pixels');

% the layout positioning is from bottom left corner in row major order
% calculate position for each axes
layout_idx = layouts(:,1)==no_axes;
assert(nnz(layout_idx)==1, 'The number of axes demanded is not supported by adjustGUIandAxeses');

% set the GUI position
set(handles.roc_gui, 'Position', [gui_starting_pos layouts(layout_idx,[4 5])]);

% center the controls panel
pos = get(handles.uipanel_main_controls, 'Position');
set(handles.uipanel_main_controls, 'Position', [ layouts(layout_idx,4)/2-pos(3)/2, border_pxls pos([3 4])]);

% get the extents where to fit the axes
axes_extents = [ border_pxls, pos(4)+2*border_pxls, layouts(layout_idx,4)-border_pxls, layouts(layout_idx,5)-top_ui_height-border_pxls ];

[x y] = meshgrid(axes_extents(1):(axes_extents(3)-axes_extents(1))/layouts(layout_idx,3):axes_extents(3), ...
                 axes_extents(2):(axes_extents(4)-axes_extents(2))/layouts(layout_idx,2):axes_extents(4));

tempx = x(1:end-1,1:end-1)'+min_gap/2;
tempy = y(1:end-1,1:end-1)'+min_gap/2;
axes_width = x(1,2)-x(1,1)-min_gap;
axes_height = y(2,1)-y(1,1)-min_gap;

% fix the height or width according to the aspect ratio
if axes_width/axes_height > aspect_ratio_to_maintain
    old_axes_width = axes_width;
    axes_width = axes_height * aspect_ratio_to_maintain;
    tempx = tempx+(old_axes_width-axes_width)/2;
else
    old_axes_height = axes_height;
    axes_height = axes_width / aspect_ratio_to_maintain;
    tempy = tempy+(old_axes_height-axes_height)/2;
end

pos = [tempx(:), tempy(:), repmat([axes_width axes_height], [no_axes 1])];

% loop over to create all the axes
for axes_idx = 1:no_axes
    axes_tag = [handles.user_data.axes_tag_prefix num2str(axes_idx)];
    
    h1 = axes('Parent',handles.roc_gui, ...
              'Box', 'on', ...
              'Units','pixels', ...
              'Position',pos(axes_idx,:), ...
              'Tag',axes_tag, ...
              'XTick', [], ...
              'YTick', [], ...
              'ZTick', []);
    
    text(0.5,0.5, ['{\color{red}Axes ' num2str(axes_idx) '}'], 'Tag',['text_' axes_tag], 'FontSize',12, 'FontWeight','bold', 'HorizontalAlignment','center', 'VerticalAlignment','middle');
    
    hcmenu = uicontextmenu('Tag', ['context_menu_' axes_tag]);
    uimenu(hcmenu, 'Label','Load overlay', 'Tag',['load_menu_' axes_tag], 'Callback', @(hObject,eventdata) menuCallbacks('menu_load_overlay_Callback', hObject, eventdata, guidata(hObject), axes_tag));
    uimenu(hcmenu, 'Label','Clear overlay', 'Tag',['clear_menu_' axes_tag], 'Callback', @(hObject,eventdata) menuCallbacks('menu_clear_overlay_Callback', hObject, eventdata, guidata(hObject), axes_tag));
    
    set(h1, 'uicontextmenu',hcmenu);
    
    handles.(axes_tag) = h1;
end


function recursiveHandleDelete(handle_list)
% recursively (by going down the children tree) deletes all the handles in a list

if isempty(handle_list)
    return;
end

for hndl = handle_list
    if ishandle(hndl)
        children_hndls = get(hndl, 'Children');
        recursiveHandleDelete(children_hndls);
        delete(hndl);
    end
end