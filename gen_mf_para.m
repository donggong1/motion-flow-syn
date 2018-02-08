function [mf, para] = gen_mf_para(h,w,opts)
% randomly generate parameters for motion flow
if(opts.isblur)
    rng('shuffle');
    para.tx = (2*rand-1)*opts.tx_max;
    para.ty = (2*rand-1)*opts.ty_max;
    para.tx_acc = (2*rand-1)*opts.tx_acc_max;
    para.ty_acc = (2*rand-1)*opts.ty_acc_max;
    
    para.tz = (2*rand-1)*opts.tz_max;
    para.cen_z = [h/2, w/2] + [(2*rand-1), (2*rand-1)].*opts.cen_z_shift_max;
    para.rot_z = (2*rand-1)*opts.rot_z_max;
    mf = gen_mf(h,w,para);
else
    mf.mu = zeros(h,w);
    mf.mv = zeros(h,w);
    mf.mag = zeros(h,w);
    mf.ori = zeros(h,w);
    para = [];
end
return