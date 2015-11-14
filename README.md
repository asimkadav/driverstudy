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


To recreate the study without using the static analysis, please load data.sql in a database and run process[1-4].sql

Here are some of the sample queries used:

%Module Parameters
% List of drivers: select driverid, name,path, bfactor from drivers where bfactor >  0
% 1161
% select count(distinct(driverid)) from driver_fns where is_proc=1 or is_devctl=1;


% Function distribution

% Class wise fn distribution:  select class,  ROUND(100*sum(is_init*loc)/sum(loc),1) init,ROUND(100*sum(is_cleanup*loc)/sum(loc),1) cleanup, ROUND(100*sum(is_ioctl*loc)/sum(loc),1) ioctl, ROUND(100*sum(is_config*loc)/sum(loc),1) config, ROUND(100*sum(is_pm*loc)/sum(loc),1) power, ROUND(100*sum(is_err*loc)/sum(loc),1) error, ROUND(100*(sum(is_proc*loc)/sum(loc)+ sum(is_devctl*loc)/sum(loc)),1) proc, ROUND(100*sum(is_core*loc)/sum(loc),1) core, ROUND(100*sum(is_intr*loc)/sum(loc),1) intr from driver_fns group by class;

% Total : select  ROUND(100*sum(is_init*loc)/sum(loc),1) init,ROUND(100*sum(is_cleanup*loc)/sum(loc),1) cleanup, ROUND(100*sum(is_ioctl*loc)/sum(loc),1) ioctl, ROUND(100*sum(is_config*loc)/sum(loc),1) config, ROUND(100*sum(is_pm*loc)/sum(loc),1) power, ROUND(100*sum(is_err*loc)/sum(loc),1) error, ROUND(100*(sum(is_proc*loc)/sum(loc)+ sum(is_devctl*loc)/sum(loc)),1) proc, ROUND(100*sum(is_core*loc)/sum(loc),1) core, ROUND(100*sum(is_intr*loc)/sum(loc),1) intr from driver_fns;

%select  class, ROUND(100*sum(is_thread*is_init)/count( driverid),1) init,ROUND(100*sum(is_thread*is_cleanup)/count( driverid),1)cleanup,ROUND(100*sum(is_thread*is_init)/count( driverid),1) ioctl, ROUND(100*sum(is_thread*is_config)/count( driverid),1) config,    ROUND(100*sum(is_thread*is_core)/count( driverid),1) core from driver_fns ;


% Unique :  select class,  ROUND(100*sum(is_init*is_unique*loc)/sum(loc),1) init,ROUND(100*sum(is_cleanup*is_unique*loc)/sum(loc),1) cleanup, ROUND(100*sum(is_ioctl*is_unique*loc)/sum(loc),1) ioctl, ROUND(100*sum(is_config*is_unique*loc)/sum(loc),1) config, ROUND(100*sum(is_pm*is_unique*loc)/sum(loc),1) power, ROUND(100*sum(is_err*is_unique*loc)/sum(loc),1) error, ROUND(100*(sum(is_proc*is_unique*loc)/sum(loc)+ sum(is_devctl*is_unique*loc)/sum(loc)),1) proc, ROUND(100*sum(is_core*is_unique*loc)/sum(loc),1) core, ROUND(100*sum(is_intr*is_unique*loc)/sum(loc),1) intr from driver_fns group by class;

%select driverid from drivers where bfactor > 0  union (select
%distinct(driverid) from driver_fns where is_proc=1 or is_devctl=1);
%
%
%select count(distinct(driverid)) from driver_fns where is_process=1  and is_core=1 and dev_call_count=0 and sync_call_count=0 and mem_call_count=0 and bus_count=0 and dma_count=0 and portmm_count=0 and kdev_count=0 and klib_count=0 and ttk=0;

%%%%% Correlation

%create table correlation2  select driver_fns.driverid,  ROUND(sum(loc),2) total,
%(select chipset from drivers where driver_fns.driverid=driverid) chip from
%driver_fns group by driver_fns.driverid order by 3;
%
% SELECT @n := COUNT(total) AS N, @meanX := AVG(chip) AS "X mean", @sumX :=
% SUM(chip) AS "X sum",@sumXX := SUM(chip*chip) "X sum of squares", @meanY :=
% AVG(total) AS "Y mean",  @sumY := SUM(total) AS "Y sum", @sumYY :=
% SUM(total*total) "Y sum of square", @sumXY := SUM(chip*total) AS "X*Y sum" FROM
% correlation2;
%
% SELECT (@n*@sumXY - @sumX*@sumY) / SQRT((@n*@sumXX - @sumX*@sumX) * (@n*@sumYY
% - @sumY*@sumY)) AS corr;
%
%  For init code:
%  create table correlation  select driver_fns.driverid,
%  ROUND(100*sum(loc*is_init)/sum(loc),2) init, (select chipset from drivers
%  where driver_fns.driverid=driverid) chip from driver_fns group by
%  driver_fns.driverid order by 3;
%
%  Device/Kernel calls
%select class,  ROUND(100*sum(ttk)/count(*),1) ttk,
%ROUND(sum(ttk_count)/sum(ttk),1) ttk_count, ROUND(100*sum(is_sync)/count(*),1)
%sync , ROUND(sum(sync_call_count)/sum(is_sync),1) scc,
%ROUND(100*sum(is_event)/count(*),1) event , ROUND(100*sum(is_thread)/count(*),1)
%thread , ROUND(100*sum(is_allocator)/count(*),1) alloc,
%ROUND(sum(mem_call_count)/sum(is_allocator),1) mcc from driver_fns group by
%class;












