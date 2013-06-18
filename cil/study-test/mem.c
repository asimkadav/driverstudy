#include <stdio.h>


int main()	{

	int a,b,c;
	int * d = malloc (4);

	a =4;
	d[2] = a;
	d[2] = 4;
	*d = 0;
	printf ("Valude of d is %d \n", *d);
	free(d);
}


