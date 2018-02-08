% Motion flow and blurry image synthesis
%%%%%%%%%%%%
% From Motion Blur to Motion Flow: a Deep Learning Solution for Removing Heterogeneous Motion Blur  
% Dong Gong, Jie Yang, Lingqiao Liu, Yanning Zhang, Ian Reid, Chunhua Shen, Anton van den Hengel, Qinfeng Shi.  
% In IEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2017.
% Email: edgong01@gmail.com (Dong Gong)
% Project page with more details: https://donggong1.github.io/blur2mflow.html
%%%%%%%%%%%%

addpath('conv_opt')
addpath('utils')

is_show = false;

data_root = 'dataset/';
image_path = [data_root, 'image/'];
inpath_list = {[image_path, 'train/'],...
    [image_path, 'test/'],...
    [image_path, 'val/']
    };
output_path = [data_root, 'data_syn/'];
outpath_list = {[output_path, 'train/'],...
    [output_path, 'test/'],...
    [output_path, 'val/']
    };

%% quantization types
% q_type='uv_original';
q_type='uv_basic';
% q_type='uv_half_multi';
% q_type='mo'; % mag and ori

%% two examples for blur level setting
opts_s.tx_max = 27;
opts_s.tx_acc_max = 0.3;
opts_s.ty_max = 27;
opts_s.ty_acc_max = 0.3;
opts_s.tz_max = 5e-3;
opts_s.cen_z_shift_max = 15;
opts_s.rot_z_max = pi/70;
opts_s.isblur = true;

% mild
opts_m.tx_max = 19;
opts_m.tx_acc_max = 0.25;
opts_m.ty_max = 19;
opts_m.ty_acc_max = 0.25;
opts_m.tz_max = 2e-3;
opts_m.cen_z_shift_max = 5;
opts_m.rot_z_max =pi/120;
opts_m.isblur = true;
%% Gaussian noise level on the blurry image
noise_level = 0.001;
%%
is_crop_boundary = true;
motion_scale = 1; % scale the generated motion flow, useless?
%% number of different motion flow for one image
num_mf = 50; % 30; 50; % total number of motion flow for each image
num_mf_m = 0;
% num_mf_m = max(round(num_mf*0.3), 0); % number for "opts_m" (30%), mixed setting
%%
for path_ite = 1:length(inpath_list)
   inpath = inpath_list{path_ite};
   outpath = outpath_list{path_ite};
   if ~exist(outpath, 'dir')
       mkdir(outpath)
   end
   dir_list = dir([inpath, '/*.jpg']);
   for file_ite = 1:length(dir_list)
       img_name = dir_list(file_ite).name;
       %% processing
       img = imread([inpath, img_name]);
       img = im2double(img);
       [h,w,d] = size(img);
       %%
       fprintf('dir=%d, img=%d/%d\n', path_ite, file_ite, length(dir_list));
       for n = 1:num_mf+1
           fprintf('dir=%d, img=%d/%d, blur_idx=%d/%d\n', path_ite, file_ite, length(dir_list), n, num_mf+1);
           %% syn motion flow (random)
           if(n<=num_mf_m)
               opts = opts_m;
               [mf, para] = gen_mf_para(h,w,opts);
           elseif(n<=num_mf)
               opts = opts_s;
               [mf, para] = gen_mf_para(h,w,opts);
           else
               % non-blurry image
               opts.isblur = false;
               [mf, para] = gen_mf_para(h,w,opts);
           end
           %% discrete quatilization
           mf.mu = round(mf.mu*motion_scale);
           mf.mv = round(mf.mv*motion_scale);
%            [mag, ori]= motion2magori(mf.mu,mf.mv);
           [mag, ori]= mfuv2mo(-mf.mv,mf.mu);
           mf.mag = mag;
           mf.ori = ori;
           %% blurring image
           x = img;
           y = zeros(size(x));
           for c = 1:d
               y(:,:,c) = gen_blurry_img(x(:,:,c), mf);
           end
           y = y*255;
           %% add gaussian noise
           y = y + randn(size(y)).*noise_level;
           %% show motion field, only for testing the code. Please remember to remove this when generating data.
           if(is_show)
               immotion = draw_mf_on_img(double(y), mag, ori);
               figure, imshow(uint8(immotion * 255));
               muv(:,:,2) = mf.mv; muv(:,:,1) = mf.mu;
               figure; subplot(1,2,1);imshow(uint8(flowToColor(muv))); title('Middlebury color coding');
               subplot(1,2,2); plotflow(muv);   title('Vector plot');
           end
           %% motion map for training
           clear mfmap
           switch(q_type)
               case 'uv_basic'
                   mfmap(:,:,1) = mf.mu;
                   mfmap(:,:,2) = mf.mv;
               case 'uv_half'
                   tmpu = mf.mu;
                   tmpv = mf.mv;
                   idx = tmpu<0;
                   tmpu(idx)=-tmpu(idx);
                   tmpv(idx)=-tmpv(idx);
                   mfmap(:,:,1) = tmpu; % right half
                   mfmap(:,:,2) = tmpv;
               case 'uv_half_multi'
                   % multi-quantization
                   tmpu = mf.mu;
                   tmpv = mf.mv;
                   idx = tmpu<0;
                   tmpu(idx)=-tmpu(idx);
                   tmpv(idx)=-tmpv(idx);
                   mfmap(:,:,1) = tmpu; 
                   mfmap(:,:,2) = tmpv;
                   mfmap(:,:,3) = mfmap(:,:,1) - mod(mfmap(:,:,1), 2); 
                   mfmap(:,:,4) = mfmap(:,:,2) - mod(mfmap(:,:,2), 2);
                   mfmap(:,:,5) = mfmap(:,:,1) - mod(mfmap(:,:,1)-1, 2);
                   mfmap(:,:,6) = mfmap(:,:,2) - mod(mfmap(:,:,2)-1, 2);                   
               case 'mo' % magnitude and orientation
                   mfmap(:,:,1) = mag;  
                   mfmap(:,:,2) = ori;
               otherwise
                   mfmap = [];
                   fprintf('Wrong q type\n');
           end
           %%
           tmpidx = find(img_name=='.');
           filename_on = img_name(1:tmpidx-1);
           %% remove boundary in training
           if(is_crop_boundary)
               bound_h = floor(max(abs(mf.mv(:)))/2);
               bound_w = floor(max(abs(mf.mu(:)))/2);
               y = y(1+bound_h:end-bound_h, 1+bound_w:end-bound_w,:);
               mfmap = mfmap(1+bound_h:end-bound_h, 1+bound_w:end-bound_w,:);
               x_gt = x(1+bound_h:end-bound_h, 1+bound_w:end-bound_w,:)*255;
               imwrite(uint8(x_gt), [outpath, filename_on, '_', num2str(n, '%03d'), '_gtimg', '.png']);
           end
           %% save results
%            save([outpath, filename_on, '_', num2str(n, '%03d'), '_bimg', '.mat'], 'y');
           imwrite(uint8(y), [outpath, filename_on, '_', num2str(n, '%03d'), '_blurryimg', '.png']);
           save([outpath, filename_on, '_', num2str(n, '%03d'), '_mfmap', '.mat'], 'mfmap');
           % save([outpath, filename_on, '_', num2str(n, '%03d'), '_mf_para', '.mat'], 'para', 'mfmap'); % save the original parameter and motion field
       end
   end
end



