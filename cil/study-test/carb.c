#include <stdio.h>
int funny () __attribute__((isolate));

main()	
{
  int b[32];
  int a = ioread16();
  int *c;
  c = ioread16();

  while (c == 0) ; 
  printf ("Calue is %d", b[a]);
  printf ("Calue is %d", *c);
  printk ("asim");
  *(c + 5) = 55;
}


int funny () {
	int a;
	int *b;
	a = 0;
    b = 0x0;
	printf ("%d", *b);
}
