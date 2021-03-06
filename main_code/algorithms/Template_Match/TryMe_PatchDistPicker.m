% Sample code for Olga to see that PatchDistPicker() works in Matlab



ImageDir = 'C:\users\brostow\data\CambridgeTraffic\CambridgeTraffic_framesAll_small\';
MATdir = sprintf( '%s*.mat', ImageDir );
MATFiles = dir( MATdir );
PNGdir = sprintf( '%s*.png', ImageDir );
PNGFiles = dir( PNGdir );

iFrame = 705 % for( iFrame = 1:numIs )

    fNameM = sprintf( '%s%s', ImageDir, MATFiles(iFrame).name );
    fNameI = sprintf( '%s%s', ImageDir, PNGFiles(iFrame).name );
    fprintf( '%s\n', fNameI );

    load( fNameM );     % Loads up a tmp variable Sp2

    I = im2double(imread( fNameI ));

    [n, m] = size(I);

    I_sp2 = segImage(I,Sp2); % Red(1,0,0) border, 2 pixels wide in total.


    Ids = unique( Sp2(:) );  % Handy if the Indexes weren't [1,2,3...].
    numIds = size(Ids,1);
    
    
    
% ====================================================================   
% Activate the code below to see how the image was split up into tiles. 
% Use the pt-inspection tool in Matlab's figure to find the index of an
% interesting cel, and enter that index as iId lower down in this code.
%    
% ====================================================================
%    CM = Build2DgraphOfCels( Sp2 ); % Make the sparse Connection Matrix:
%    % CM is 'true' when cel i  is N, S, E, or W of  cel j
%    %spy(CM); % View the connection matrix.
%
%     MidPts = zeros( numIds, 2 );
%
%     for( iId = 1:numIds )
%         [Ys Xs] = find(Sp2 == Ids(iId));  % Returns [ (Which rows down)    (Which cols) ]
%         MidPts(iId, 1:2) = [sum(Ys) sum(Xs)] / size(Xs,1);
%     end
% 
% 
%     % Graph: Overlay the Connection Matrix
%     CMlowTri = tril(CM); % Don't need upper triangle (above diag), bec it just repeats edges.
%     imshow( I_sp2 );
%     hold on;
% 
%     %numEdges = nnz(CM);
%     for( iId = 1:numIds )
%         MyNeighbs = find(CMlowTri(iId,:));
%         numNeighbs = size(MyNeighbs, 2);
%         from = MidPts(iId,:);
%         for( iNeighb = 1:numNeighbs )
%             to = MidPts(MyNeighbs(iNeighb),:);
%             line([from(2) to(2)], [from(1) to(1)]); % Note that line() plots (row, col) ie (y, x).
%         end
%     end
%     hold off;
% 
%     CelsInGray = Sp2;
%     WhereEdges = find( I_sp2(:,:,1) == 1 );
%     CelsInGray(WhereEdges) = 0;
%     figure, imagesc(CelsInGray);
% ====================================================================
% ====================================================================







iFrameNext = iFrame+1;
fNameInext = sprintf( '%s%s', ImageDir, PNGFiles(iFrameNext).name );
Inext = im2double(imread( fNameInext ));







SearchPadding = [20 20 20 20];

% Debug: turning off looping for now.
    iId = 643;
%    iId = 388;
%    iId = 636;
% for( iId = 1:numIds )

    [Ys Xs] = find(Sp2 == Ids(iId));
    % Now we have all the coord's of this blob.
    
    
    % Two equivalent ways to grab the sub-image:
    minXs = min(Xs); 
    maxXs = max(Xs);    
    minYs = min(Ys); 
    maxYs = max(Ys);
    img_Cel = I(minYs:maxYs,   minXs:maxXs, :);  % Need colRange, rowRange
    % OR
    % upper-left corner, width, height:
    % rect_Cel = [min(Xs)     min(Ys)     max(Xs)-min(Xs)    max(Ys)-min(Ys)];
    % img_Cel = imcrop( I, rect_Cel );  % NOTE: imcrop uses (x,y) NOT (col, row)

    bound = GetCelBoundPixels( Sp2, iId, minXs, maxXs, minYs, maxYs );
    % Now have list of this cel's Red-pixels.
    
    [cropCoordsFullI availPadW availPadN] = ...
        IndexesToSearchInFullImg(size(Inext), size(img_Cel), [minYs minXs], SearchPadding);
    subI = Inext(cropCoordsFullI(1):cropCoordsFullI(2), cropCoordsFullI(3):cropCoordsFullI(4), :);

    imgMaskCel = GetCelMaskPixels( Sp2, iId, minXs, maxXs, minYs, maxYs );

    % Just use green channel for now (ie :,:,2).
    [ncc movedSE scoreMaxs] = ...
        PatchDistPicker( img_Cel(:,:,2), subI(:,:,2), ...
                         [availPadW availPadN], ...
                         'maskedNCC', ...   % builtinNCC, builtinNCCsearchInside, plain_ncc, maskedNCC, plain_nssd, masked_nssd
                         imgMaskCel );

    figure, 
    surf(ncc), shading flat


%     [nssd movedSE scoreMaxs] = ...
%         PatchDistPicker( img_Cel(:,:,2), subI(:,:,2), ...
%                          [availPadW availPadN], ...
%                          'masked_nssd', ...   % builtinNCC, builtinNCCsearchInside, plain_ncc, maskedNCC, plain_nssd, masked_nssd
%                          imgMaskCel );
%     figure, 
%     surf(nssd), shading flat
    
    
    
    
    %paintColors = flipud(  jet( 7 )   )
    %   Show where the cel came from:
	Idirty = PaintMovedBoundsOnIm( bound, [minYs minXs], [0 0], [1], I, 1.0 );
    %     pngFileName = sprintf( '%s_%.5d_%s_%.1d.png', 'tmp/00705/NCC_', iId, 'iCel_', 0);
    %     GrabFigToFile( pngFileName );  % using default size == '-r155'
    
    
    Idirty = PaintMovedBoundsOnIm( bound, [minYs minXs], movedSE, [1:4], Inext, scoreMaxs );
    %     pngFileName = sprintf( '%s_%.5d_%s_%.1d.png', 'tmp/00705/NCC_', iId, 'iCel_', 1);
    %     GrabFigToFile( pngFileName );  % using default size == '-r155'

%end




% Section for trying out various sizes of padding
%
% for iPad = 41:300
%     SearchPadding = iPad * [1 1 1 1];
%     [cropCoordsFullI availPadW availPadN] = ...
%         IndexesToSearchInFullImg(size(Inext), size(img_Cel), [minYs minXs], SearchPadding);
%     subI = Inext(cropCoordsFullI(1):cropCoordsFullI(2), cropCoordsFullI(3):cropCoordsFullI(4), :);
% 
%     imgMaskCel = GetCelMaskPixels( Sp2, iId, minXs, maxXs, minYs, maxYs );
%     % Just use green channel for now (ie :,:,2).
%     [ncc movedSE scoreMaxs] = ...
%         PatchDistPicker( img_Cel(:,:,2), subI(:,:,2), ...
%                          [availPadW availPadN], ...
%                          'maskedNCC', ...   % builtinNCC, builtinNCCsearchInside, plain_ncc, maskedNCC, plain_nssd, masked_nssd
%                          imgMaskCel );
%     Idirty = PaintMovedBoundsOnIm( bound, [minYs minXs], movedSE, [1:4], Inext, scoreMaxs );
%     pngFileName = sprintf( '%s_%.5d_%s_%.1d.png', 'tmp/sweepPad/maskedNCC_', iPad, 'iPad_', 1);
%     GrabFigToFile( pngFileName );  % using default size == '-r155'
% end

clear SearchPadding cropCoordsFullI
clear img_Cel subI
clear scoreMaxs indMaxs scoreMins indMins;
clear moved_E moved_S moved
clear minXs maxXs minYs maxYs;


%%





