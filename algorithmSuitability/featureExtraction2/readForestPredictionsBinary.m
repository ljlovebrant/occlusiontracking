clear all
close all

sceneID = 18;%2, 3 and 4, but for 4 there is no ground truth is some areas - effects plot
al = 4; %1 ba, 2 tv, 3 hs, 4 fl, 5 max confidence

ipdir  = fullfile(pwd, '../data/'); % or test
fvFile = 'fv';

load([ipdir num2str(sceneID) '/' num2str(sceneID)])
load([ipdir num2str(sceneID) '/' num2str(sceneID) fvFile]);
[angBA epeBA] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvBA(:,:,1), uvBA(:,:,2));
[angTV epeTV] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvTV(:,:,1), uvTV(:,:,2));
[angHS epeHS] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvHS(:,:,1), uvHS(:,:,2));
[angFL epeFL] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvFL(:,:,1), uvFL(:,:,2));

imx = size(im1,1);
imy = size(im1,2);
i = 1;
scores = zeros(imx*imy,5);
for algo = {'fl'} %{'ba', 'tv', 'hs', 'fl'}
    
    alIt = char(algo);
    resdir = ['../data/' alIt '/results/'];
    
    resultsFileName = [resdir num2str(sceneID) '_prediction.data'];
    
    % % read in predicted file
    res = zeros(imx*imy,1);
    res = textread(resultsFileName,'%f');
    scores(:,i) = res;
    res = reshape(res, imy, imx)'; % need the transpose to read correctly

    imshow(res);
    colormap summer;
    set(gcf, 'units', 'pixels', 'position', [100 100 imy imx], 'paperpositionmode', 'auto');
    set(gca, 'position', [0 0 1 1], 'visible', 'off');
    print('-dpng', [resdir num2str(sceneID) '_posterior'], '-r0');
    
    %     figure
    %     imagesc(res)
    i = i + 1;
end


%%
% evaluate prediction - based on max confidence - Note still using areas of
% low confidence
% [val ind] = max(scores,[],2);
% scores(:,5) = val;
% labels = reshape(ind, imy, imx)';
% confidence = reshape(val, imy, imx)';
% 
% BApre = logical(labels==1);
% TVpre = logical(labels==2);
% HSpre = logical(labels==3);
% FLpre = logical(labels==4);
% 
% pre = zeros(imx, imy, 2);
% pre(:,:,1) = uvBA(:,:,1).*BApre + uvTV(:,:,1).*TVpre + uvHS(:,:,1).*HSpre + uvFL(:,:,1).*FLpre;
% pre(:,:,2) = uvBA(:,:,2).*BApre + uvTV(:,:,2).*TVpre + uvHS(:,:,2).*HSpre + uvFL(:,:,2).*FLpre;
% [angPre epePre] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), pre(:,:,1), pre(:,:,2));
% pts = sum(sum(mask));
% opt = sum(epePre(mask))/pts;
% 
% 
% 
% %%
% % loop over threshold and only give average end point error for areas
% % greater than confidence - needs to be done per algorithm
% 
% %%
% if (al == 1)
%     epe = epeBA;
% elseif(al==2)
%     epe = epeTV;
% elseif(al==3)
%     epe = epeHS;
% elseif(al==4)
%     epe = epeFL;
% elseif(al==5)% max combination
%     epe = epePre;
% end
% 
interval = [0:0.001:1];
% optVals = zeros(length(interval),1);
% noPixels = zeros(length(interval),1);
% confid = reshape(scores(:,al), imy, imx)';
% i = 1;
% 
% for t  = interval
%     % note including boundaries
%     noPixels(i) = sum(sum(confid>t));
%     if (noPixels(i) ~= 0)%divide by zero
%         optVals(i) = sum(epe(confid>t))/noPixels(i);
%     end
%     i  = i+1;
% end
% optVals(optVals==NaN) = 0; % divide by zero case
% 
% %% Epe after thresholding
% figure;plot(noPixels, optVals)
% for i=1:9    
%    hold on; plot(noPixels(1+i*100),optVals(1+i*100),'bo')
% end
% hold on;text(noPixels(801),optVals(801),'0.8', 'Color',[0 0 1])
% hold on;text(noPixels(501),optVals(501),'0.5', 'Color',[0 0 1])
% hold on;text(noPixels(201),optVals(201),'0.2', 'Color',[0 0 1])
% xlabel('No Pixels')
% ylabel('Average Epe')
% title('Confidence Thresholding (Error Training 1 pixel) - Urban2');
% 
% 
% %% Confidence
% figure; imagesc(confid); colorbar; colormap gray
% title('FL Decision Confidence - Urban2')
% axis off


%% ROC
tuv = readFlowFile([ipdir num2str(sceneID) '/1_2.flo']);
mask = loadGTMask( tuv, 0 );
labels = (mask == 0);

errorToTest = 1;
i = 1;
fpr = zeros(length(interval),1);
tpr = zeros(length(interval),1);
for t  = interval
    
    tmpC1 = reshape(scores(:,1)>=t, imy, imx)';
%     tmpE1 = ((epe.*tmpC1)<errorToTest);
    
    tmpC2 = reshape(scores(:,1)<t, imy, imx)';
%     tmpE2 = ((epe.*tmpC2)>=errorToTest);
    
    tp = sum( tmpC1(:) & labels(:));
    fp = sum( tmpC1(:) & ~labels(:));
    tn = sum( tmpC2(:) & ~labels(:));
    fn = sum( tmpC2(:) & labels(:));
    
    fpr(i) = fp / (fp+tn);
    tpr(i) = tp / (tp+fn);
    i = i+1;
end

figure
plot(fpr,tpr)
for i=1:9    
   hold on; plot(fpr(1+i*100),tpr(1+i*100),'bo')
end
hold on;text(fpr(801)+0.02,tpr(801),'0.8', 'Color',[0 0 1])
hold on;text(fpr(501)+0.02,tpr(501),'0.5', 'Color',[0 0 1])
hold on;text(fpr(201)+0.02,tpr(201),'0.2', 'Color',[0 0 1])

title('ROC of Optical Flow Confidence - Sponza')
xlabel('FPR')
ylabel('TPR')
print('-depsc', '-r0', [resdir num2str(sceneID) '_roc']);


