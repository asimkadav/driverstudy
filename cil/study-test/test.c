#include <stdio.h>
#define HERMES_AUX_ENABLED 0
#define HERMES_CONTROL 0
#define hermes_read_reg ioread16


int ioread16()
{
    static int c = 0;
    return printf(c++);
}

int printk (char * a)
{
  printf (a);

}

int honey ()
{
   int * a;
  // a = ioread16();
   
   //if (a != NULL)
  // printf (*a);	
	
    return 0;
}

int readb ()  __attribute__((_isolate))
{
    return 0;
}


int request_irq(unsigned int f, int (*func) ,
                               unsigned long flags , char const   *devname , void *dev_id ) 
{
    func;
    return 0;
}

int writel () {
    return 0;
}

int ww ()  {
    int i = 0;
    int blah_blah_blah;
    ioread16();
    writel();
    while (ioread16()&&(i<4)) {i++;return -1;}
    return 0;
}

int main ()
{
    int j,bunny, count, status, flags, val;
    register int  i;
    int port;
    int a[10];
    int *b;
    int ticks = 10;
    int ioaddr = 0;
    int Wn7_MasterStatus = 0;
    char const *p;
    void * c;

    //val = ioread16();
    //val += 16;
    //j = a[val];

    
//
  //  count = 0;
   // i = 1000;
   

//
     status = ioread16();
    if (status = 1)	{
		printk ("sdsds");
		return (-14);
	}
/*
   
    if (request_irq (100, ww, flags, p, c))
            ;
    count = 1;
 */
end:
    return 0;
}
