function y = gen_blurry_img(x, mf)
% blurring iamge according to mf
y = motionBlurConv(double(x), mf.mag, mf.ori); % to be updated
% y = motionBlurConv_mirror(double(x), mf.mag, mf.ori); % to be updated
return