#include "Nucleus.h"

Nucleus::Nucleus (Basis & basis, int nbNeut, int nbProt, arma::field<arma::mat> & TBME) 
    : System("Nucleus", basis, arma::ivec {nbNeut,nbProt}, std::vector<std::string> {"Neutrons","Protons"}, TBME)
{}

void calcH0(arma::field<arma::mat> & H, int type) {
    (void) H;
    (void) type;
}

void calcH(arma::field<arma::mat> & H, arma::field<arma::mat> & RG) {
    (void) H;
    (void) RG;
}

void calcKineticField(arma::field<arma::mat> & RG){
    (void) RG;
}
