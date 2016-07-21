#include <iostream>	// cout cin
#include <stdio.h>	// sprintf
#include <fstream>	// ofstream
#include <iomanip>	// setprecision()
#include <stdlib.h>	// abs
#include <math.h>	// sin
#include <vector>	// vectors
#include "inf_SW.h"	// header file

using namespace std;	// no need to put std:: before any cout, etc.

int selectFunc = 3;	// Select the potential you want:
			// 1. Infinite square well
			// 2. Finite square well
			// 3. Woods-Saxon potential

// Variables
double     a = 75.;	// Box width  [fm]
double     l = 35.;	// Well width [fm] (don't use yet)
double     h = 0.01;	// Mesh width [fm]
double    V0 = 20;	// Well depth [MeV] (don't use yet)
double  eMin = -100.;	// Min limit  [MeV]
double  eMax = 0.;	// Max limit  [MeV]
double eStep = 1.;	// Step between different energies in brute force approach, needs getting rid of

int nProton  = 82;
int nNeutron = 126;

double wfStep1 = 0;
double wfStep2 = 1e-5;

double convEng = 1e-13;// Convergence energy
//double convEng = 0.5;// Convergence energy

double hm_fac = 20.75;	// units? MeV?

// Variable used to check if the wavefunction has crossed x axis
// between different energies
double wfPrev, wfLast;

// Main code
int main()
{
	double trialE = (eMax-eMin)/2;	// IS this the best way to start the bisection method?
	vector<double> wf_val;		// Vector for wave function values

	// Nice stuff for terminal output
	cout << "\n*************************************************" << endl;
	cout << "*\tEigen E [MeV]\tOutput filename\t\t*" << endl;

	double firstE;

	int nSteps = (eMax-eMin)/eStep;

	// Loop for the calculation
	for(int jj=0; jj<nSteps; jj++) // (eMax+eMin)
	{
		
		wf_val.push_back(wfStep1);	// Initiate step 0 and step 1 WF values, if don't do this will not get past first calc.
		wf_val.push_back(wfStep2);	// NOTE: amplitude of calculated wavefunctions are arbitrary but defined by magnitude of
					//	 of this step, this is important when defining if calc. has converged.

		// Loop for calculating wavefunction values across the mesh, using the Numerov algorithm
		for(int i=0; i<a/h; i++)
		{
			wf_val.push_back(numerovAlgorithm(eMin, wf_val.at(i+1), wf_val.at(i), i*h));
		}

		// Assign value to wfLast
		wfLast = wf_val.at(-1+wf_val.size());

		// This is where will converge the calculation
		// Need if jj>0 condition otherwise will have no previous value for wavefunction
		if(jj>0)
		{
			// Check if there is a change in sign of wavefunction values at the limit of the box for
			// the most recent two different energies (wfPrev/wfLast negative if this is the case)
			if(wfPrev/wfLast < 0)
			{
				double eigenEng;	// initiate variable for energy eigenvalue

				// Check whether wavefunction at limit has pos. or neg. gradient at limit of box,
				// then calls the convergence function to calculate an energy eigenvalue
				if(wfPrev<wfLast)
				{
						eigenEng = converge(eMin-eStep,eMin,wfPrev,wfLast);
				}
				else
				{
						eigenEng = converge(eMin,eMin-eStep,wfLast,wfPrev);
				}

				// Clear previous wafefunction vector and initiate first two steps
				wf_val.clear();
				wf_val.push_back(wfStep1);
				wf_val.push_back(wfStep2);

				// Calculate eigenfunction using Numerov
				for(int i=0; i<a/h; i++)
				{
					wf_val.push_back(numerovAlgorithm(eigenEng, wf_val.at(i+1), wf_val.at(i), i*h));
				}

				// Write results to file with filename including energy eigenvalue
				char filename[512], eigEng[512];
				sprintf(filename,"output_%1.4f.dat",eigenEng);
				sprintf(eigEng,"%1.4f",eigenEng);
				ofstream opFile;
				opFile.open(filename);
				for(int k=0; k<a/h; k++) opFile << h*k << "\t" << wf_val.at(k) << endl;
				opFile.close();

				// Output energy eigenvalue and the name of the file results are saved to
				cout << "*\t" << eigEng << "\t\t" << filename << "\t*"  << wfPrev << "\t\t" << wfLast << "\t*" << endl;
			}

		}

		// Store the last value of the Numerov calculation 
		// so as to check whether change in sign in next iteration
		wfPrev = wf_val.at(-1+wf_val.size());

		wf_val.clear(); // clear wf_val vector for next calculation with different trial energy
		eMin += eStep;	// increase energy.....will get rid of this
	}
	cout << "*************************************************\n" << endl;	// nice stuff for terminal output
}

// Numerov algorithm function.
//
// INPUT ARGUMENTS:
//     E = trial energy
//   f_x = Wavefunction value from previous step ( f(x)   from TALENT school notes)
// f_x_h = Wavefunction value from two steps ago ( f(x-h) from TALENT school notes)
double numerovAlgorithm(double E, double f_x, double f_x_h, double x)
{
	double a[3];		// Array for Numerov coefficients
	double vx = (E-V(x)) / hm_fac;	// Numerov potential

	a[0] = 2. * (1. - 5./12. * vx * h * h);	// Coeff. for f(x)
	a[1] = 1. * (1. + 1./12. * vx * h * h);	// Coeff. for f(x-h)
	a[2] = 1. * (1. + 1./12. * vx * h * h);	// Coeff. for f(x+h)

	double nuWF = ((a[0] * f_x) - (a[1] * f_x_h)) / a[2]; // Calculate wavefunction value
	return nuWF;	// Return nuWF value when function called
}

// Function to converge on energy eigenvalue
//
// INPUT ARGUMENTS:
//  eLo = the energy of the step with the lowest wavefunction value
//  eHi = the energy of the step with the highest wavefunction value
// wfLo = lower wavefunction value of the two energy steps
// wfHi = higher wavefunction value of the two energy steps
double converge(double eLo, double eHi, double wfLo, double wfHi)
{
	double trialE, diffE=eStep;
	vector<double> wf_val;

	// While condition to carry on bisection convergence energy difference between
	// trial energy and previous energies is small enough
	while (diffE>convEng)
	{
		trialE = (eHi+eLo)/2;		// Trial energy based on average of two previous energies
		wf_val.push_back(wfStep1);	// Initiate Step 0 wavefunction value
		wf_val.push_back(wfStep2);	// Initiate Step 1 wavefunction value
		diffE = trialE-eLo;		// Difference between new trial energy and previous energies (used to check convergence)

		// Loop for calculating wavefunction values across the mesh, using the Numerov algorithm
		for(int i=0; i<a/h; i++)
		{
			wf_val.push_back(numerovAlgorithm(trialE, wf_val.at(i+1), wf_val.at(i), i*h));
		}
		// Work out which wavefunction is......I think this is where the convergence function is messing up.
		if (wf_val.at(-1+wf_val.size()) < 0)
		{
			eLo  = trialE;
			wfLo = wf_val.at(-1+wf_val.size());
		}
		else
		{
			eHi  = trialE;
			wfHi = wf_val.at(-1+wf_val.size());
		}
		wf_val.clear();	// clear wavefunction vector
	}
	return trialE;	// return the trial energy value that meets the tolerance condition
}

double V(double x)
{
	if (selectFunc == 1) return infSW();
	if (selectFunc == 2) return finSW(x);
	if (selectFunc == 3) return woodsSaxon(x);
}

// Infinite square well potential
double infSW()
{
	return 0;
}

// Finite square well
double finSW(double x)
{
	double c = a/2;
	if( (x < ((a-l)/2))  || (x > ((a+l)/2)) ) 
		return V0;
	else
		return 0;
}

// Woods-Saxon potential
double woodsSaxon(double x)
{
	double WS;
	int         A = nProton + nNeutron;
	double     r0 = 1.27;
	double      R = r0 * pow(A,1./3);
	double a_comp = 0.67;
	double coeffV = -51 + 33*((nNeutron-nProton)/A);

	if(x>a/2)
	{
		WS = coeffV * (1 / ( 1 + exp( ((x-(a/2))-R)/a_comp )));
	}
	else 
	{
		WS = coeffV * (1 / ( 1 + exp( ((-x+(a/2))-R)/a_comp )));
	}
	return WS;
}







