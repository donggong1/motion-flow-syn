% visulize motion flow on an image
function imMotion = draw_mf_on_img(im, mag, ori)
%mag = squeeze(flow(:,:,1));
%ori= squeeze(flow(:,:,2));
[r,c,d] = size(im);
inte = 21;
if d > 1
    im = double((rgb2gray(uint8(im)))) / 255;
end
imMotion(:,:,1) = 0.7 * 1 + 0.4 * im;
imMotion(:,:,2) = 0.7 * 1 + 0.4 * im;
imMotion(:,:,3) = 0.7 * 1 + 0.4 * im;
ori = 90 - ori;
rec_wid = 1;
for i = inte : inte : r - inte
    for j = inte : inte : c - inte
        l = max(mag(i, j), 1);
        o = ori(i, j);

        ft = ((fspecial('motion', l, o)));
        kkk = fspecial('average', 2);
        ft = conv2(ft, kkk, 'same');
        
        
        ft = ft / max(ft(:));
        [w,h] = size(ft);
        
        [xs, ys] = find(ft > 0);
        ids_ker = sub2ind([w,h], xs, ys);
        xs = xs - (w+1) / 2;
        ys = ys - (h+1) / 2;
        aa = i + xs;
        bb = j + ys;
        %% !!
        aa = min(max(aa, 1), r);
        bb = min(max(bb, 1), c);
        ids_img = sub2ind([r,c], aa, bb);
        %% 
        imMotion(ids_img) = 1 * ft(ids_ker) + (1 - ft(ids_ker)) .* imMotion(ids_img);
        imMotion(ids_img + r * c) = (1 - ft(ids_ker)) .* imMotion(ids_img + r * c);
        imMotion(ids_img + 2 * r * c) = (1 - ft(ids_ker)) .* imMotion(ids_img + 2 * r * c);
        
        % draw a rectangle around the centered pixel
        if(0)
            for pp = i - rec_wid : i +  rec_wid
                for qq = j - rec_wid : j + rec_wid
                    imMotion(pp, qq, 1) = 0;
                    imMotion(pp, qq, 2) = 0;
                    imMotion(pp, qq, 3) = 1;  
                end
            end
        end
        imMotion(i, j, 1) = 0;
        imMotion(i, j, 2) = 0.5;
        imMotion(i, j, 3) = 0;
        
       % if i == 323 & j == 561
       %     i
       % end
    end
end


