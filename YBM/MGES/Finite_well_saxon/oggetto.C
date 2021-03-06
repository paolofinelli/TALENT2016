#include"Esercizio.h"

	double numerov_algorithm_woods(double energy, double f0, double f_,double r, double S, double L, double J, float T){
		double v=0., a[3];
		if(T==-1./2.){
			a[0] = 2. * (1. - 5./12. * v_neutron(energy,r,S,L,J) * pow(h_width,2));
			a[1] = 1. * (1. + 1./12. * v_neutron(energy,r-h_width ,S,L,J) * pow(h_width,2));
			a[2] = 1. * (1. + 1./12. * v_neutron(energy,r+h_width,S,L,J) * pow(h_width,2));
			return (a[0] * f0 - a[1] * f_) / a[2];
		}
		else if(T==1./2.){
			a[0] = 2. * (1. - 5./12. * v_proton(energy,r,S,L,J) * pow(h_width,2));
			a[1] = 1. * (1. + 1./12. * v_proton(energy,r-h_width,S,L,J) * pow(h_width,2));
			a[2] = 1. * (1. + 1./12. * v_proton(energy,r+h_width,S,L,J) * pow(h_width,2));
			return (a[0] * f0 - a[1] * f_) / a[2];
		}
	}

	double v_neutron(double energy, double r,double S, double L, double J){
		return (energy-potential_woods(r)-centrifug_term(r,L)-potential_spin_orbit(r,S,L,J))/m_factor;
	}

	double v_proton(double energy, double r,double S, double L, double J){
		return (energy-potential_woods(r)-centrifug_term(r,L)-potential_spin_orbit(r,S,L,J)-potential_coulomb(r))/m_factor;
	}

	double potential_woods(double r){
		double V = -51.+33.*(N-Z)/(N+Z);
		double R = r0*pow(A,1./3.);
		return V/(1+exp((r-R)/0.67));
	}

	double centrifug_term(double r, double L){
		return m_factor*L*(L+1)/pow(r,2);
	}

	double potential_coulomb(double r){
		double R = r0*pow(A,1./3.);
		if(r<=R)
			return Z*e/(2.*R)*(3-pow(r/R,2));
		else
			return Z*e/r;
	}

	double potential_spin_orbit(double r, double S, double L, double J){
		if(L!=0){
			double V = -51.+33.*(N-Z)/(N+Z);
			double R = r0*pow(A,1./3.);
			double S_L = 1./2.*(J*(J+1)-L*(L+1)-3./4.);
			double df = -1./(pow(1+exp((r-R)/0.67),2))*(1./0.67)*exp((r-R)/0.67);
			return -0.22*V*1./r*df*S_L*pow(r0,2);
		}
		else
			return 0;
	}

	double normalise(double eigen, double n_step_width_box, double S, double L, double J, float T){
	vector<double> wfWork;
	wfWork.push_back(0.05);
	wfWork.push_back(0.1);

	double sum = 0.;
	for(int i=1; i<n_step_width_box+1; i++) wfWork.push_back(numerov_algorithm_woods(eigen, wfWork[i], wfWork[i-1], i*h_width + h_width, S, L, J, T));
	for(int i=1; i<n_step_width_box+1; i++) sum += h_width*pow(wfWork[i],2);

	wfWork.clear();
	return sum;
    }

    double particleFromDensity(double * density, double n_step_width_box){
        	// Integrate total radial density 'density' to calculate A
        double particles = 0.0;

        for(int i=2; i<n_step_width_box+1; i++){
            particles += density[i]*4.*M_PI*(pow(i*h_width+h_width,2));
        }

        return h_width*particles;
    }

	double coulombPotentialHF(std::vector<double> density, double r){
		double integ1 = 0.;
		double integ2 = 0.;
		double integ3 = 0.;

		for(int i=0;i<=r/h_width,++i){
			integ1 += density[i]*r*r;
			integ2 += density[i]*r;
		}
		for(int i=0;i<=width_box/h,++i){
			integ3 += density[i]*r;
		}

		return 4.*M_PI*q*h* (integ1/r - integ2 + integ3);
	}
