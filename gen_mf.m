function [mf] = gen_mf(h,w,para)
%% generate mf according to para
%%
mu = zeros(h,w);
mv = zeros(h,w);

%% x trans
lefttx = para.tx*(1-para.tx_acc/2);
% rightx = para.tx*(1+para.tx_acc/2);
tx_line = [1:w].*(para.tx_acc*para.tx/w) + lefttx;
tx_mat = repmat(tx_line, h, 1);
% mu = mu + para.tx;
mu = mu + tx_mat;
%% y trans
botty = para.ty*(1-para.ty_acc/2);
ty_line = [h:-1:1]'.*(para.ty_acc*para.ty/h) + botty;
ty_mat = repmat(ty_line, 1, w);
% mu = mu + para.tx;
mv = mv + ty_mat;
% mv = mv + para.ty;

%% z rotation
[wcoor,hcoor] = meshgrid(1:w, 1:h);
zrot_l = sqrt((wcoor-para.cen_z(2)).^2+(hcoor-para.cen_z(1)).^2);
zrot_s = tan(para.rot_z) .* zrot_l;

tmph = (1+h-hcoor)-(para.cen_z(1));
tmpw = wcoor-para.cen_z(2);

alpha = atan2(tmph(:), tmpw(:));%*(180/pi)
alpha = reshape(alpha, h, w);
alpha_1 = alpha-pi/2;
mu = mu + sin(alpha_1).*zrot_s;%????
mv = mv + cos(alpha_1).*zrot_s;

%% z trans (forward)
s = para.tz.*zrot_l.^1.5;
mu = mu + s.*sin(alpha);
mv = mv + s.*cos(alpha);
%%
mf.mu = mu;
mf.mv = mv;
% [mag, ori]= motion2magori(mu,mv);
% mf.mag = mag;
% mf.ori = ori;

%%
% figure; imagesc(mu);
% colorbar
% figure; imagesc(mv);
% colorbar

%%
% immotion = drawMotionField(double(ones(h,w)), mag, ori);
% figure, imshow(uint8(immotion * 255));
% muv(:,:,2) = mf.mu;
% muv(:,:,1) = -mf.mv;

% draw color map
% figure; subplot(1,2,1);imshow(uint8(flowToColor(muv))); title('Middlebury color coding');
% subplot(1,2,2); plotflow(muv);   title('Vector plot');

return