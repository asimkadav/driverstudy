#include <stdio.h>
#define HERMES_AUX_ENABLED 0
#define HERMES_CONTROL 0
#define hermes_read_reg ioread16

int dma_map_page(int a)
{
  return 0;
}


int ioread162()
{
    static int c = 0;
    return c++;
}

