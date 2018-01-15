create database;

mysql> create database driverstudy;

mysql> USE driverstudy;

mysql> source struct.sql

mysql> source data.sql

Take a coffee break..

mysql> source process.sql

mysql> source process2.sql

mysql> source process3.sql

 select class,  ROUND(100*sum(is_init*loc)/sum(loc),1) init,ROUND(100*sum(is_cleanup*loc)/sum(loc),1) cleanup, ROUND(100*sum(is_ioctl*loc)/sum(loc),1) ioctl, ROUND(100*sum(is_config*loc)/sum(loc),1) config, ROUND(100*sum(is_pm*loc)/sum(loc),1) power, ROUND(100*sum(is_err*loc)/sum(loc),1) error, ROUND(100*(sum(is_proc*loc)/sum(loc)+ sum(is_devctl*loc)/sum(loc)),1) proc, ROUND(100*sum(is_core*loc)/sum(loc),1) core, ROUND(100*sum(is_intr*loc)/sum(loc),1) intr from driver_fns group by class;


 select  ROUND(100*sum(is_init*loc)/sum(loc),1) init,ROUND(100*sum(is_cleanup*loc)/sum(loc),1) cleanup, ROUND(100*sum(is_ioctl*loc)/sum(loc),1) ioctl, ROUND(100*sum(is_config*loc)/sum(loc),1) config, ROUND(100*sum(is_pm*loc)/sum(loc),1) power, ROUND(100*sum(is_err*loc)/sum(loc),1) error, ROUND(100*(sum(is_proc*loc)/sum(loc)+ sum(is_devctl*loc)/sum(loc)),1) proc, ROUND(100*sum(is_core*loc)/sum(loc),1) core, ROUND(100*sum(is_intr*loc)/sum(loc),1) intr from driver_fns;

mysql> update driver_fns set is_unique = is_init + is_cleanup + is_intr + is_config + is_err + is_proc + is_pm + is_core + is_ioctl + is_devctl;

update driver_fns set is_unique=0 where is_unique > 1 ;

kernel function calls per driver

 select class,  ROUND(100*sum(is_init*is_unique*loc)/sum(loc),1) init,ROUND(100*sum(is_cleanup*is_unique*loc)/sum(loc),1) cleanup, ROUND(100*sum(is_ioctl*is_unique*loc)/sum(loc),1) ioctl, ROUND(100*sum(is_config*is_unique*loc)/sum(loc),1) config, ROUND(100*sum(is_pm*is_unique*loc)/sum(loc),1) power, ROUND(100*sum(is_err*is_unique*loc)/sum(loc),1) error, ROUND(100*(sum(is_proc*is_unique*loc)/sum(loc)+ sum(is_devctl*is_unique*loc)/sum(loc)),1) proc, ROUND(100*sum(is_core*is_unique*loc)/sum(loc),1) core, ROUND(100*sum(is_intr*is_unique*loc)/sum(loc),1) intr from driver_fns group by class;





device function calls per driver


select class, ROUND(sum(ttk_count)/count(distinct (driverid)),1) ttkc,
 ROUND(sum(sync_call_count)/count(distinct (driverid)),1) syncc,
 ROUND(sum(mem_call_count)/             count(distinct (driverid)),1) memc,
 ROUND(sum(kdev_count)/count(distinct (driverid)),1) kdevc,
 ROUND(sum(klib_count)/count(distinct (driverid)),1) klibc from driver_fns group
 by class;




device funciton calls per driver
select class, ROUND(sum(dev_call_count)/count(distinct (driverid)),1) ttd,
 ROUND(sum(portmm_count)/count(distinct (driverid)),1) portmmio,
 ROUND(sum(dma_count)/count(distinct (driverid)),1) dma,
 ROUND(sum(bus_count)/count(distinct (driverid)),1) bus
  from driver_fns group
 by class



Avg calls per function
select class, sum(ttd)/count(*), sum(ttk)/count(*), sum(is_sync)/count(*), sum(is_event)/count(*), sum(is_thread)/count(*), sum(is_dma)/count(*), sum(is_port)/count(*), (sum(ttk) - sum(is_port) - sum(is_dma))/count(*) from driver_fns group by class;


Driver calls per function
select class, count(*) fns, sum(ttd)/count(*)*100 ttd, sum(ttk)/count(*)*100 ttk, sum(is_sync)/count(*)*100 sync , sum(is_allocator)/count(*)*100 alloc, sum(is_dma)/count(*)*100 dma , sum(is_port)/count(*)*100 portio, (sum(ttd) - sum(is_port) - sum(is_dma))/count(*)*100 mmio from driver_fns group by class;


Driver calls per driver
select class, count(*) fns, sum(ttd)/count(*)*100 ttd, sum(ttk)/count(*)*100 ttk, sum(is_sync)/count(*)*100 sync , sum(is_allocator)/count(*)*100 alloc, sum(is_dma)/count(*)*100 dma , sum(is_port)/count(*)*100 portio, (sum(ttd) - sum(is_port) - sum(is_dma))/count(*)*100 mmio from driver_fns group by class;


%age of functions
select class,  sum(ttk)/count(*)*100 ttk, sum(ttk_count)/count(*) ttk_count, sum(is_sync)/count(*)*100 sync , sum(sync_call_count)/count(*) scc, sum(is_event)/count(*)* 100 event , sum(is_thread)/count(*)*100 thread , sum(is_allocator)/count(*)*100 alloc, sum(mem_call_count)/count(*) mcc from driver_fns group by class;


%age of functions that use thread or event driven or both
select class,   sum(is_sync)/count(*)*100 sync , sum(sync_call_count)/count(*) scc, sum(is_event)/count(*)* 100 event , sum(is_thread)/count(*)*100 thread from driver_fns group by class;


select class,   sum(is_sync)/count(*)*100 sync , sum(is_event)/count(*)* 100 event , sum(is_thread)/count(*)*100 thread from driver_fns group by class;

select CONCAT( '('  ,  ROUND(sum(is_sync)/count(*)*100,1) ,   ',' , @rownum:=@rownum+1, ')' )    from driver_fns, (SELECT @rownum:=0) r where class in ('acpi',  'bluetooth' ,'firewire', 'gpu', 'gpio', 'input', 'isdn', 'media', 'serial', 'sound', 'usb', 'video')  group by class;





 
select CONCAT( '(' , @rownum:=@rownum+1, ', ', ROUND(sum(mem_call_count)/count(distinct (driverid)),1) , ')' )    from driver_fns, (SELECT @rownum:=0) r where class in ('acpi',  'bluetooth' ,'firewire', 'gpu', 'input', 'isdn', 'media', 'serial', 'sound', 'video', 'ata', 'ide', 'block', 'mtd', 'md', 'scsi', 'atm', 'net', 'infiniband', 'uwb') group by class;



select class, CONCAT( '(' , @rownum:=@rownum+1, ', ', ROUND(sum(mem_call_count)/sum(ttk_count)*100,1) , ')' )    from driver_fns, (SELECT @rownum:=0) r where class in ('acpi',  'bluetooth' ,'firewire', 'gpu', 'input', 'isdn', 'media', 'serial', 'sound', 'video') group by class;

 select CONCAT( '(' , @rownum:=@rownum+1, ', ', ROUND(sum(mem_call_count)/count(distinct (driverid)),1) , ')' )    from driver_fns, (SELECT @rownum:=10) r where class in ('ata',  'block','ide','md', 'mtd',  'scsi') group by class;

select CONCAT( '(' , @rownum:=@rownum+1, ', ', ROUND(sum(mem_call_count)/count(distinct (driverid)),1) , ')' )    from driver_fns, (SELECT @rownum:=16) r where class in ('atm',  'infiniband', 'net', 'uwb') group by class;



select CONCAT( '(' , @rownum:=@rownum+1, ', ', ROUND(sum(portmm_count)/count(distinct (driverid)),1) , ')' )    from driver_fns, (SELECT @rownum:=0) r where class in ('acpi',  'bluetooth' ,'firewire', 'gpu', 'input', 'isdn', 'media', 'serial', 'sound', 'video') and is_core=1 group by class;

select class, CONCAT( '(' , @rownum:=@rownum+1, ', ', ROUND(sum(portmm_count)/count(distinct (driverid)),1) , ')' )    from driver_fns, (SELECT @rownum:=0) r where class in ('acpi',  'bluetooth' ,'firewire', 'gpu', 'input', 'isdn', 'media', 'serial', 'sound', 'video', 'ata',  'block','ide','md', 'mtd',  'scsi', 'atm',  'infiniband', 'net', 'uwb') group by class order by find_in_set(class, ' acpi,  bluetooth , firewire, gpu, input, isdn, media, serial, sound, video, ata, block,  ide, md, mtd, scsi, atm, infiniband, net, uwb ') asc ;





