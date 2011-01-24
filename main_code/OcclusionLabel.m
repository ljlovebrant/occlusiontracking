classdef OcclusionLabel < AbstractLabel
    %OCCLUSIONLABEL label which gives occluded regions in flow
    
    properties (Constant)
        LABEL_TYPE = 'Occlusion GT Label';
        LABEL_SHORT_TYPE = 'OGT';
    end
    
    
    methods
        function [ label data_idxs idxs_per_label ] = calcLabelTraining( obj, comp_feat_vec, MAX_MARKINGS_PER_LABEL, extra_label_info )
        % creates label data which can be used in training stage of a
        % classifier. It would produce at maximum MAX_MARKINGS_PER_LABEL
        % labels belonging to data_idxs
        
            [ labels ignore_labels ] = obj.calcLabelWhole( comp_feat_vec, extra_label_info );
            
            % remove the ignored labels
            labels = double(labels);
            labels(ignore_labels) = inf;
            
            % want equal contribution from each class
            non_occl_regions = find(labels==0);
            occl_regions = find(labels==1);
            
            % shuffle
            idxs_per_label  = min([length(non_occl_regions) length(occl_regions) MAX_MARKINGS_PER_LABEL]);

            num_clusters = 1;
            
            data_idxs = {};
            
            if num_clusters == 1
                shuff = randperm(length(non_occl_regions));
                label(1) = 0;
                data_idxs{1} = non_occl_regions(shuff(1:idxs_per_label));

                shuff = randperm(length(occl_regions));
                label(2) = 1;
                data_idxs{2} = occl_regions(shuff(1:idxs_per_label));
            else
%                 clustered_filepath = fullfile(comp_feat_vec.scene_dir, sprintf('feature_clusters_%s_2.mat', num2str(comp_feat_vec.getUniqueID())));
%                 
%                 if ~exist(clustered_filepath, 'file')
%                     [ cluster_idxs ] = OcclusionLabel.clusterFeatures(comp_feat_vec, num_clusters);
% 
%                     num_class = zeros(num_clusters, 2);
%                     for cluster_idx = 1:num_clusters
%                         psb_idxs = find(cluster_idxs == cluster_idx);
%                         num_class(cluster_idx,:) = [nnz(labels(psb_idxs)==0) nnz(labels(psb_idxs)==1)];
%                     end
% 
%                     image_sz = comp_feat_vec.image_sz;
%                     save(clustered_filepath, 'cluster_idxs', 'num_class', 'image_sz');
%                 else
%                     load(clustered_filepath);
%                     clear image_sz;
%                 end
%                 
%                 label(1) = 0;
%                 data_idxs{1} = [];
%                 
%                 label(2) = 1;
%                 data_idxs{2} = [];
%                 
%                 pickup_rate_noccl = ceil(idxs_per_label / num_clusters);
%                 pickup_rate_occl = ceil(idxs_per_label / num_clusters);
%                 
%                 % sort according to the number of samples in each cluster
%                 % for a particular label
%                 [sorted_vals sorted_idx] = sort(num_class);
%                 
%                 % get non-occluded idxs
%                 for cluster_idx = 1:num_clusters
%                     psb_idxs = find(cluster_idxs == sorted_idx(cluster_idx,1));
%                     
%                     non_occl_regions = find(labels(psb_idxs)==0);
%                     
%                     if ~isempty(non_occl_regions)
%                         shuff = randperm(length(non_occl_regions));
%                         pickup_idxs = min(pickup_rate_noccl, length(non_occl_regions));
%                         data_idxs{1} = [data_idxs{1}; psb_idxs(non_occl_regions(shuff(1:pickup_idxs)))];
%                     end
%                     pickup_rate_noccl = ceil((idxs_per_label - length(data_idxs{1})) / (num_clusters-cluster_idx));
%                 end
%                 
%                 % get occluded idxs
%                 for cluster_idx = 1:num_clusters
%                     psb_idxs = find(cluster_idxs == sorted_idx(cluster_idx,2));
%                 
%                     occl_regions = find(labels(psb_idxs)==1);
%                     
%                     if ~isempty(occl_regions)
%                         shuff = randperm(length(occl_regions));
%                         pickup_idxs = min(pickup_rate_occl, length(occl_regions));
%                         data_idxs{2} = [data_idxs{2}; psb_idxs(occl_regions(shuff(1:pickup_idxs)))];
%                     end
%                     pickup_rate_occl = ceil((idxs_per_label - length(data_idxs{2})) / (num_clusters-cluster_idx));
%                 end

                label(1) = 0;
                data_idxs{1} = [];
                
                label(2) = 1;
                data_idxs{2} = [];
                
                clustered_filepath = fullfile(comp_feat_vec.scene_dir, sprintf('feature_clusters_%s_2.mat', num2str(comp_feat_vec.getUniqueID())));
                
                num_clusters_noccl = 20;
                num_clusters_occl = 4;
                
                if ~exist(clustered_filepath, 'file')
                    cluster_idxs = uint32(zeros(size(labels)));
                    [ cluster_idxs(labels==0) ] = OcclusionLabel.clusterFeatures(comp_feat_vec, num_clusters_noccl, labels==0);
                    [ cluster_idxs(labels==1) ] = OcclusionLabel.clusterFeatures(comp_feat_vec, num_clusters_occl, labels==1) + num_clusters;
                    
                    image_sz = comp_feat_vec.image_sz;
                    save(clustered_filepath, 'cluster_idxs', 'image_sz');
                else
                    load(clustered_filepath);
                    clear image_sz;
                end
                
                pickup_rate_noccl = ceil(idxs_per_label / num_clusters_noccl);
                pickup_rate_occl = ceil(idxs_per_label / num_clusters_occl);
                
                % sort according to the number of samples in each cluster
                % for a particular label
                [sorted_vals sorted_idx] = sort(histc(cluster_idxs(labels==0), 1:num_clusters_noccl));
                
                % get non-occluded idxs
                for cluster_idx = 1:num_clusters_noccl
                    psb_idxs = find(cluster_idxs == sorted_idx(cluster_idx));
                    
                    if ~isempty(psb_idxs)
                        shuff = randperm(length(psb_idxs));
                        pickup_idxs = min(pickup_rate_noccl, length(psb_idxs));
                        data_idxs{1} = [data_idxs{1}; psb_idxs(shuff(1:pickup_idxs))];
                    end
                    pickup_rate_noccl = ceil((idxs_per_label - length(data_idxs{1})) / (num_clusters_noccl-cluster_idx));
                end
                
                
                [sorted_vals sorted_idx] = sort(histc(cluster_idxs(labels==1), num_clusters_noccl+1:num_clusters_noccl+num_clusters_occl));
                
                % get occluded idxs
                for cluster_idx = 1:num_clusters_occl
                    psb_idxs = find(cluster_idxs == num_clusters_noccl+sorted_idx(cluster_idx));
                    
                    if ~isempty(psb_idxs)
                        shuff = randperm(length(psb_idxs));
                        pickup_idxs = min(pickup_rate_occl, length(psb_idxs));
                        data_idxs{2} = [data_idxs{2}; psb_idxs(shuff(1:pickup_idxs))];
                    end
                    pickup_rate_occl = ceil((idxs_per_label - length(data_idxs{2})) / (num_clusters_occl-cluster_idx));
                end
            end
        end
        
        
        function [ labels ignore_labels ] = calcLabelWhole( obj, comp_feat_vec, extra_label_info )
        % outputs all the labels given the data features (usually not used) 
        % and customizable extra information (here the GT flow)
        
            assert(isfield(extra_label_info, 'calc_flows'), 'CalcFlows object is needed for computing occlusion label');
            
            mask = extra_label_info.calc_flows.gt_mask;
            labels = (mask == 0)';
            labels = labels(:);
            
            % inform user about the labels they should ignore
            if ~isempty(extra_label_info.calc_flows.gt_ignore_mask)
                fprintf(1, 'IGNORING labelling of %d/%d pixels for %s\n', nnz(extra_label_info.calc_flows.gt_ignore_mask), numel(extra_label_info.calc_flows.gt_ignore_mask), comp_feat_vec.scene_dir);
                
                ignore_labels = extra_label_info.calc_flows.gt_ignore_mask';
                ignore_labels = ignore_labels(:);
            else
                ignore_labels = false(size(labels));
            end
        end
    end
    
end

