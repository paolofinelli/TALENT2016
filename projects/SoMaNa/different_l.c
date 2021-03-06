#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "harmon.h"
#include <gsl/gsl_poly.h>
#include <gsl/gsl_sf_legendre.h>

// Module to calculate two-body matrix elements; currently it is specifically adapted to the simple V outlined in the manuals for the course. Later we will of course modify it for the more complex case, inevitably breaking everything in the process.

// The calculation proceeds in four steps, really; first the function to be integrated in the 1D integral is calculated, then it is integrated, then it is all repeated for the 2D integral (r1, r2).

// There is a lot of passing functions as arguments. Even I don't believe it's all correct.

// 1D function.

// Gauss-Laguerre integration program.

// Laguerre polynomials.

double galag (int n, int n1, int n2, int n3, int n4, double m, double w,double r1, double r2, double V);

double twodgalag (int n, int n1, int n2, int n3, int n4, double m, double w, double V,double kappa, double l);

double fun1 (double kappa, double V,double r1, double r2)

	{
	
		double res;
		/* arg = x/(-2.*kappa*r1*r2)*/
		res = 1./2.*(V/(-kappa*(r1+0.01)*(r2+0.01)))*exp(-1*kappa*(r1*r1+r2*r2));
		
		return res;
	
	}

double sum ( double kappa, double V,double r1, double r2, double phi1, double phi2, double theta1, double theta2)
{
	double res, term, dummy1;
	int l, m;
	res = 0;
	for (l = 0; l <= l_max; l++){
		for (m = -l; m <= l; m++){
			dummy1 = galag(5,n1,n2,n3,n4,m,w,r1,r2,V);
			term = 4*pi*dummy1*gsl_sf_legendre_sphPlm (int l, int m, double theta1)*gsl_sf_legendre_sphPlm (int l, int m, double theta2)*(cos(double phi1)*cos(double phi2) - sin(double phi1)*sin(double phi2));	
			res = res + term;
		}
	}
	
	return res;
}

double fun2 (double kappa, double V, double m, double w,double r1, double r2,int n1, int n2, int n3, int n4)
	
	{
	
		double res,res1, res2, dummy1;
		
		dummy1 = galag(5,n1,n2,n3,n4,m,w,r1,r2,V);
		
		printf ("AAaaaa! \n\n\n n1 = %d  n2 = %d  n3 = %d  n4 = %d",n1,n2,n3,n4);
		
		res1 = dummy1*r1*r1*r2*r2*Rnl(n1,0.0,m,w,r1)*Rnl(n2,0.0,m,w,r2)*Rnl(n3,0.0,m,w,r1)*Rnl(n4,0.0,m,w,r2)*exp(r1)*exp(r2);
		
		res2 = dummy1*r1*r1*r2*r2*Rnl(n1,0.0,m,w,r1)*Rnl(n2,0.0,m,w,r2)*Rnl(n3,0.0,m,w,r2)*Rnl(n4,0.0,m,w,r1)*exp(r1)*exp(r2);
				
		
		printf("\n\n\n R = %lf R = %lf R = %lf R = %lf",Rnl(n1,0,m,w,r1),Rnl(n2,0.0,m,w,r2),Rnl(n2,0.0,m,w,r1),Rnl(n4,0.0,m,w,r2));
		
		res = res1-res2;
		
		return res;
	
	}

// 1D Gauss-Laguerre quadrature. The function is sadly not general; since a lot of arguments need to be passes to the function it is specifically tailored to the problem at hand.

/* double galag (int n, double (*funcp)(double, int, int, int, int,double,double,double), int n1, int n2, int n3, int n4, double m, double w,double r1, double r2, double V) */

double galag (int n, int n1, int n2, int n3, int n4, double m, double w,double r1, double r2, double V)

	{
	
	int i;
	
	double *coefficients;
	
	double *solutions; 
	
	double *ws;
	
	double res = 0;
	
	coefficients = (double*) malloc ((n+1)*sizeof(double)); 
	
	ws = (double*) malloc ((n+1)*sizeof(double)); 

	solutions = (double*) malloc ((2*n)*sizeof(double));
	
	for (i=0; i<=n; i++)
		
		{
		coefficients[i] = binomial(n, i)*pow((-1),i)/factorial(i); // Coefficients for the Laguerre polynomials.
		}
	gsl_poly_complex_workspace *dummy = gsl_poly_complex_workspace_alloc (n+1);
	
	gsl_poly_complex_solve (coefficients, n+1, dummy, solutions); // Roots of the Laguerre polynomials.
	
	gsl_poly_complex_workspace_free (dummy);
	
	for (i=0; i<n; i++)
		
		{
			ws[i] = solutions[2*i]/(pow(n+1, 2)*pow(laguerre(n+1,solutions[2*i]),2)); // Calculation of weights.
						
			printf("\n\n\n root = %f weight = %f \n", solutions[2*i], ws[i]);
			
			res+= ws[i]*fun1(1.487,200,r1,r2)*gsl_sf_legendre((int)l, double solutions[2*i]/(-2.*kappa*(r1+0.01)*(r2+0.01)));; // Summation of weights with function values at mesh points.
			printf("\n\n\n sum = %f \n", res);
		}
	
	free(ws);
	
	free(solutions);
	
	free(coefficients);
	
	return res;
	
	}

// 2D G-L quadrature. Analogous to the function above, except the summation over one index is replaced by a double-loop summation.

/* double twodgalag (int n, double (*funcp)(double, double, int, int, int, int,double,double,double), int n1, int n2, int n3, int n4, double m, double w, double V) */

double twodgalag (int n, int n1, int n2, int n3, int n4, double m, double w, double V,double kappa, double l)

	{
	
	int i, j;
	
	double *coefficients;
	
	double *solutions; 
	
	double wi, wj;
	
	double res = 0;

	coefficients = (double*) malloc ((n+1)*sizeof(double)); 

	solutions = (double*) malloc ((2*n)*sizeof(double));
	
	for (i=0; i<=n; i++)
		
		coefficients[i] = binomial(n, i)*pow((-1),i)/factorial(i);
	
	gsl_poly_complex_workspace *dummy = gsl_poly_complex_workspace_alloc (n+1);
	
	gsl_poly_complex_solve (coefficients, n+1, dummy, solutions);
	
	gsl_poly_complex_workspace_free (dummy);
	
	for (i=0; i<n; i++)
		
		for (j=0; j<2*n; j+=2)
		
			{
				{
				wi = solutions[2*i]/(pow(n+1, 2)*pow(laguerre(n+1,solutions[2*i]),2)); 
	// printf("wi = %f \n", wi);
				
				wj = solutions[2*j]/(pow(n+1, 2)*pow(laguerre(n+1,solutions[2*j]),2));
			 
	// printf("wj = %f \n", wj);
		
			res+= wi*wj*fun2(kappa,V,m,w,solutions[2*i], solutions[2*j], n1, n2, n3, n4);
			
			printf ("\n\n\n 2DGALAG \t sol1 = %lf sol2 = %lf wi=%lf wi=%lf res =%lf",solutions[2*i],solutions[2*j],wi,wj,res);
			}
		}
	
	free(solutions);
	
	free(coefficients);
	 // Freeing up memory.
	
	return res;
	
	}
