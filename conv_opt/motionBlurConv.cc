/*
     
      Perform spatially-variant convolution, the blur kernel is computed locally given motion length and orientation map.
  
           Written by Jian SUN, XJTU, jiansun@mail.xjtu.edu.cn
	
      Inputs: 
           x: input image
           bmag: the input spatial variant motion length, size of [W, H]
           bori: the input spatial variant motion orientation, size of [W, H]
 
      Output:
           R: the output convolution result
*/

#include <stdlib.h>
#include <math.h>
#include "mex.h"

#define M_PI  3.1415926535897932

#define eps 2.2204e-16f
#define sign(n) (n<0?-1.0f:1.0f)
#define ABS(x) (x<0?-x:x)

/* ----------------------------------------------------------------------- */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
/* ----------------------------------------------------------------------- */
{  mxArray       *matrix_X, *matrix_bmag, *matrix_bori;
   double        *X, *bmag, *bori;
 
   int            w_img, h_img, w_ker, h_ker, w_ker_half, h_ker_half, offSet_img,offSet_ker, off_x, off_y, i, j, l, k, num_cand, ik, k_curr_idx;
   unsigned int   dims[2];
   

   /* Extract parameters */
   matrix_X    = (mxArray *)prhs[0];
   X  = mxGetPr(matrix_X);
   matrix_bmag     = (mxArray *)prhs[1];
   bmag  = mxGetPr(matrix_bmag);
   matrix_bori = (mxArray *)prhs[2];
   bori  = mxGetPr(matrix_bori);
   
   w_img = mxGetM(matrix_X); 
   h_img = mxGetN(matrix_X);

  // printf("%d, %d \n", w_img, h_img);
   
   /* Initialize output parameters */
   plhs[0] = mxCreateDoubleMatrix(w_img, h_img, mxREAL);
   double *R = mxGetPr(plhs[0]);
   double *src_img, *dst;

   /* Perform convolution */
   int len, sx, sy; 
   int y0= 69, x0 = 336;
   
   double half, phi, cosphi, xsign, sinphi, x2lastpix,  mag, ori,dist2line, dist2cent, linewdt = 1, sumKernel = 0;
   for (j = 0; j < h_img; j++)
   {   
       for(i = 0; i < w_img; i++)
       {  
           /* Set indicex */
           src_img  = X + j * w_img + i;
           dst  = R + j * w_img + i;

           /* Generate kernel value */
           mag = bmag[j * w_img + i];
           ori = bori[j * w_img + i];
           half = (mag - 1) / 2.0f;
           phi = fmod(ori, 180) / 180 * M_PI;

           cosphi = cos(phi);
           sinphi = sin(phi);
           xsign = sign(cosphi);

           double tmp = half*cosphi + linewdt*xsign - mag*eps;
           sx = (floor(ABS(tmp)));
           tmp = half*sinphi + linewdt - mag*eps;
           sy = (floor(ABS(tmp)));
           
                   
           //if (j == y0 & i == x0)
           //{
               //printf("%f  %f %f %d %d \n", mag, ori, half, sx, sy);
               //printf(" %d %d \n", sx, sy);
              
               //printf("%f  %f %f %f %f %f\n", half, cosphi, linewdt, xsign, mag, eps);
               //printf("%f %f \n",half*cosphi + linewdt*xsign - mag*eps, half*sinphi + linewdt - mag*eps);
           //}
           

           /* Convolution at each location */
           sumKernel = 0;*dst = 0;
           for(l = -sy; l <= sy; l++) // y
           {
               //if (j == y0 & i == x0)
               //    printf(" \n ");
               for(k = -sx; k <= sx; k++)  // x
               {
                     // compute the kernel value at currret location
                     dist2line = l * cosphi + k * sinphi;
                     dist2cent = sqrt(double(l * l + k * k));
                     
                     // if (j == y0 & i == x0)
                     // printf(" %d %d %f %f \n ", l, k, dist2line, dist2cent);
                     if (ABS(dist2line) <= linewdt & dist2cent >= half) // if it is the end point
                     {
                        x2lastpix = half - ABS((k + dist2line*sinphi)/cosphi);
                        dist2line = sqrt(double(pow(dist2line, 2) + pow(x2lastpix, 2)));
                        // if (j == 294 & i == 197)
                        //     printf(" %d %d %f %f \n ", l, k, dist2line, x2lastpix);
                     }  

                     
                     // if (j == y0 & i == x0)
                     //   printf(" %f  %f %f %f \n", dist2line, linewdt, eps, ABS(dist2line));
                     dist2line = linewdt + eps - ABS(dist2line);
                     
                     if (dist2line<0) dist2line = 0;
                    
                     // compute the convolution result
                     offSet_ker = (l + h_ker_half) * w_ker + k + w_ker_half;
                     off_x = (i + k < w_img & i + k >= 0) ? k : (i + k < 0 ? -i : w_img - 1 - i);
                     off_y = (j + l < h_img & j + l >= 0) ? l : (j + l < 0 ? -j : h_img - 1 - j);
                     offSet_img = (off_y) * w_img + off_x;
                     *dst += dist2line * (*(src_img + offSet_img));  /**/ 

                     sumKernel += dist2line;
                     
                     // if (j == y0 & i == x0)
                     //  {
                     //     printf("( %d %d:  %f) ", l, k, dist2line);
                     //  }
                }   
               
           }

           if (sumKernel > 0)
           {
               *dst /= sumKernel;
               
              //if (j == y0 & i == x0)
              //{
              //   printf("  (%f %f) ", sumKernel, *dst);
              //}
           }
       }   
  }
   
}
