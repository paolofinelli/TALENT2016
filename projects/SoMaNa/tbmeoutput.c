#include <stdio.h>
#include <stdlib.h>
#include "gauss-laguerre.h"
// #include "potential.h"
#include "harmon.h"
#include "tbme.h"

void tbmeprint (double m, double w, int n)

	{
		
		double V = 200.00;
		
		int n1, n2, n3, n4;
		
		FILE *TBMEOUT;
		
		TBMEOUT = fopen("tbme.out", "w");
		
		fprintf (TBMEOUT, "n1 \t n2 \t n3 \t n4 \t TBME \n");
		
		for (n1=0; n1<=n; n1++)
		
			for(n2=0; n2<=n; n2++)
			
				for (n3=0; n3<=n; n3++)
		
					for(n4=0; n4<=n; n4++)
					
						{
						
							fprintf (TBMEOUT,"%d \t %d \t \%d \t %d \t %lf \n", n1,n2,n3,n4, int2(fun2,n1,n2,n3,n4,m, w, V/m));
						
						}
		
		fclose(TBMEOUT);
	
	}
