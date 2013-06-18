int d();
int e();
int a();

struct ethtool_ops {
	    int (*ndo_open)();
	    int (*ndo_close)();
	    int (*ndo_start_xmit)();
};

static const struct ethtool_ops e100_ethtool_ops = {
	.ndo_open       = d,
	.ndo_close       = e,
	.ndo_start_xmit   = a,
};  


#include <stdio.h>
int d()
{
  kfree();
  spin_lock();
  kfree();
  kfree();
  e();
}

int e()
{
  kfree();
}


int b()
{
  c();
}

int a()
{
    b();
}

int main(void)	
{
  
  kfree();
  c();
}

int c()
{
  kfree(); 
  spin_lock_irq();
  d();
}

