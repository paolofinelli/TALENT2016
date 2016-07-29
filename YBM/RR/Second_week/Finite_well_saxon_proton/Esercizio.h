#ifndef _Esercizio_H_
#define _Esercizio_H_

	#include <iostream>
	#include <cmath>
	#include <vector>
	#include <fstream>
	#include <iomanip>
	#include <sstream>


	#define width_box 22.
	#define h_width 0.01
	#define r0 1.27
	#define e 1.

	#define A 208.
	#define N 126.
	#define Z 82.

	#define prec 1E-10
	#define m_factor 20.73553

	using namespace std;

	double numerov_algorithm_woods(double energy, double f0, double f_,double r,double S, double L, double J);
	double numerov_algorithm_woods_proton(double energy, double f0, double f_,double r, double S, double L, double J);
	double centrifug_term(double r, double L);
	double potential_woods(double r);
	double potential_spin_orbit(double r, double S, double L, double J);
	double potential_coulomb(double r);
	double normalise(double eigen, double n_step_width_box, double S, double L, double J);

#endif