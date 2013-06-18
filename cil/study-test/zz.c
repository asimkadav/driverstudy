#include <stdio.h>

int ioread16()
{
  return 0;
}

int main ()
{
  int i,j,bunny;
  int a[10];
  int *b;
  int ticks = 10;


  while ((ioread16()) || (i<j && i==2) || (i==j) && ioread16() > 2) {
      i++;
    if (bunny)
        goto LostCause;
    goto end;
  }    

LostCause:
  
end:
  return 0;
} 
