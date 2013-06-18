#include <stdio.h>
#define HERMES_AUX_ENABLED 0
#define HERMES_CONTROL 0
#define hermes_read_reg ioread16
#include "hello.h"
int asim1 [20];
int __param_str_asim = 1;

struct block_device_operations {
  int transfer_ioctl;
} *sim;

static struct block_device_operations joop = {
   .transfer_ioctl =0,
};
int yy()
{
  __udelay();
 return ioread16();

}

int zz()
{
 return yy();
}

int zz_intr()
{
  schedule();
  schedule();
  return;
}

int ioread16()
{
    static int c = 0;
    return printf(c++);
}

int printk (char * a)
{
  printf (a);
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
  spin_lock();
}

int asm_printk_23 (char * a)
{
  printf(a);
}

int schedule(void)	{
readb();
 inb();
 return;
}
int usb_string(int a,int b, int c, int d)	{
 return;
}
int honey ()
{
   int * a;
  // a = ioread16();
   
   //if (a != NULL)
  // printf (*a);	
	
    return 0;
}

int readb ()
{
    return 0;
}


int request_irq(unsigned int f, int (*func) ,
                               unsigned long flags , char const   *devname , void *dev_id ) 
{
    func = func;
    return 0;
}

int writel (int i) {
    //while (i){;} ;       
    printk("asim");
    ioread16();
    schedule(); 
    return 0;
}

int yww ()  {
    int i,b,a,rc = 0;
    int blah_blah_blah;
    writel(0);
    while (b){	   
    msleep(0); i++; 
    }
    return 0;
}

int ww ()  {
    int i,b,a,rc = 0;
    int blah_blah_blah;
    //writel();
    while (b){	   
    while (a )  {if (i>200) {return -14; } i++; } }
    return 0;
}

// Used to test inter-procedural taint passing.
void msleep (int status)	{

  while (status) {;}
  printk(""); 
  return;
}

int main ()
{
    int j,bunny, count, status, flags, val;
    register int  i;
    int port, rc;
    int a[10], d;
    int *b;
    int ticks = 10;
    int ioaddr = 0;
    int Wn7_MasterStatus = 0;
    char const *p;
    void * c;
    int transfer_ioctl;
    //val = ioread16();
   // val += 16;


    pci_save_state();
    j = sim->transfer_ioctl;	
    rc = j;
  
    if ((j>1) || (rc <1))
    msleep(j);
  
    while (i) {
	    i++;
	    schedule();
    } 
    for (j=0;j<5;j++) {;}
    
//
  //  count = 0;
   // i = 1000;
   

//i
     usb_string(a,b,d,c);
     c = ioread16();
     writel(rc);
     printk("asim");
     printk(d); 
     schedule();	
    if (status = 1)	
		{ asm_printk_23 ("zzz"); rc = -14; 
		rc =  (-14);}
	else {if (j> 10) rc = -12;
        }
    	

//   kmalloc (sizeof(struct ide_acpi_hwif_link), 1); 
 //  kmalloc (sizeof(struct ide_acpi_hwif_link), 1); 
    if (request_irq (100, ww, flags, p, c))
            ;
    count = 1;

end:
    return 0;
}
