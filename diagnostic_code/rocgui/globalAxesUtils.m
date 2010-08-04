function [ varargout ] = globalAxesUtils( varargin )
% evaluate function according to the number of inputs and outputs
if nargout(varargin{1}) > 0
    [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
else
    feval(varargin{:});
end



function setImageForAllAxes( handles )
% sets the background image to all the axes and assigns the context menu to
%   that image

a = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    setImageForAxes( handles, axes_idx );
end

% adjust the uicontextmenu handles
adjustUicontextmenuCallback( handles );



function setImageForAxes( handles, axes_idx )
axes_handle = handles.([handles.user_data.axes_tag_prefix num2str(axes_idx)]);

tag_name = get(axes_handle, 'Tag');
    
% delete all the previous children
delete(get(axes_handle, 'Children'));

image(uint8(rgb2gray(handles.user_data.user_images(axes_idx).im1) * handles.user_data.colorspace_scaling_tp), 'Parent',axes_handle);

% set the axes properties
set(axes_handle, 'DataAspectRatio', [1 1 1], 'Box','off', 'XColor',get(handles.roc_gui,'Color'), 'YColor',get(handles.roc_gui,'Color'), ...
    'Units','pixels', 'Tag',tag_name, 'XTick',[], 'YTick',[], 'ZTick',[]);



function adjustUicontextmenuCallback( handles )
% used for adjusting all the context menus (attaching to the most image) in
%   all the axes'

a = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re);
for axes_idx = 1:length(a)
    menu_callback = get(a(axes_idx), 'Uicontextmenu');
    axes_children = get(a(axes_idx), 'Children');
    
    im_children = findobj(axes_children, 'Type', 'image');
    
    if all(ishandle(menu_callback)) && ~isempty(im_children)
       % add callback to top most image
       set(im_children(1), 'Uicontextmenu', menu_callback);
    end
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



function [ all_axes_h ] = getAllAxesHandlesSorted(handles)
% find all the axes
all_axes_h = findall(handles.roc_gui, '-regexp', 'Tag', handles.user_data.axes_search_re);

if length(all_axes_h) > 1
    % sort by axes no.
    [temp sorted_idx] = sort(cellfun(@(x) str2num(x{1}{1}), regexp(get(all_axes_h, 'Tag'), '(\d+)$', 'tokens')));
    all_axes_h = all_axes_h(sorted_idx);
end



function deleteOverlayImages(handles, axes_no)
curr_axes_h = handles.([handles.user_data.axes_tag_prefix num2str(axes_no)]);
c = get(curr_axes_h, 'Children');

c = findall(c, 'Type', 'image');    % filter out any thing other than images

has_background = ~isempty(handles.user_data.user_images(axes_no).im1);

if ~isempty(c)
    % dont delete the boundary image on the axes
    if get(handles.boundary_chkbox, 'Value')
        % delete the lower image only if the background has not been set
        delete(c(2:end-has_background));
    else
        % delete the lower image only if the background has not been set
        delete(c(1:end-has_background));
    end
end



function switchContextMenuClear(handles, axes_no, enable_disable)
% disable overlay clear button
uicontextmenu_clear_h = findobj('Tag', [handles.user_data.axes_clear_menu_prefix num2str(axes_no)]);
set(uicontextmenu_clear_h, 'Enable', enable_disable);
