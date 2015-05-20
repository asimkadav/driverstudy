Driver Study
=============

Driver study is a project to understand the Linux driver source code using static analysis. This repository consists of the static analysis tools to generate data, the driver analysis results in CSV format and database scripts to create and post-process the results from static analysis. There is also a sample output from Linux 2.6.37.6. The post-processing scripts were only tested for this kernel. For a newer kernel, additional processing may be needed to ensure accuracy of results.

Software Required to re-run static analysis
============================================
The following software is required to re-run the static analysis on driver source. Any Linux OS Ocaml (3.08 or higher). Download from here or install it from within your distribution using yum or apt-get. CIL. 

  -- Steps to install CIL

  - Install OCaml from your linux distribution. Make sure ocaml is in your path. 

  - Run "ocaml -version". It should return 3.08 or higher. Install CIL from HERE (this github). Download, untar the above file and run: 
  
  ./configure; make; make install 

  This will generate the executable cilly in cil/bin/cilly. 
  
  Ensure this executable is in path. ($PATH) 
  
  Driver study modifies cilly to introduce a new -dodrivers flag to test drivers for hardware dependence bugs. To test any driver, locate the corresponding Makefile for the driver and add the following lines: CC=cilly --dodrivers EXTRA_CFLAGS+= --save-temps --dodrivers -I myincludes LD=cilly --dodrivers AR=cilly --mode=AR Now build the driver, using the command make. This should show list of driverstudy results. Drivers with multiple object files

If you want to run this study over drivers that consist of multiple files, like e1000. Add the following lines to your top-level Makefile. For example, drivers/net/e1000/Makfile. CC=cilly --merge --dodrivers EXTRA_CFLAGS+= --save-temps --dodrivers -D HAPPY_MOOD -DCILLY_DONT_COMPILE_AFTER_MERGE -DCILLY_DONT_LINK_AFTER_MERGE -I myincludes LD=cilly --merge --dodrivers AR=cilly --merge --mode=AR These lines run driver study analysis on the combined file. This enables taint propogation across different files in a driver module. Contact

Please email me(kadav in the domain of cs.wisc.edu) for any questions about this study.
