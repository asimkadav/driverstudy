#include <stdio.h>

main()	
{
  int b[32];
  int a = ioread8();
  int *c;
  c = ioread16();


  
  printf ("Calue is %d", b[a]);
  printf ("Calue is %d", *c);
}
