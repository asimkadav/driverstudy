update driver_fns set is_proc=1, cloc =1 where driverid in (select driverid from drivers
    where path like '%proc%' and path not like '%processor%');  
update driver_fns set is_ioctl=1 where driverid in (select driverid from drivers
    where path like '%ioctl%');  
update driver_fns set is_devctl=1, cloc=1 where driverid in (select driverid from drivers
    where path like '%sysfs%');
update driver_fns set is_devctl=1 where name like '%sysfs%';
update driver_fns set is_init=1 where driverid in (select driverid from drivers
    where path like '%init%');
 update driver_fns set is_config=1 where driverid in (select driverid from
    drivers where path like '%config%');
update driver_fns set is_pm=1 where driverid in (select driverid from drivers
    where path like '%power%');
update driver_fns set is_err=1 where driverid in (select driverid from drivers
    where path like '%error%');
update driver_fns set is_devctl=1, cloc=1 where driverid = (select driverid from drivers
    where path like '%sysctl%');
update driver_fns set is_pm=1 where name like '%power%' and name not like
'%power_of_%';
update driver_fns set is_pm=1 where name like '%proc%' and name not like
'%process%';
update driver_fns set is_ioctl=1 ,cloc=1 where name like '%ioctl%';
update driver_fns set is_devctl=1 , cloc=1 where name like '%sysctl%';
update driver_fns set is_err=1 where name like '%error%';
update driver_fns set is_core=1, cloc=1, is_intr=1 where name like '%irq_handler%';
update driver_fns set is_core=1, cloc=1,  is_intr=1 where name like '%interrupt';
update driver_fns set is_core=1, cloc=1, is_intr=1 where name like '%interrupt_handler';
update driver_fns set is_core=1, cloc=1, is_intr=1 where name like '%flush%';
update driver_fns set is_core=1, cloc=1, is_intr=1 where name like '%intr_handler';
update driver_fns set is_core=1, cloc=1, is_intr=1 where name like '%rx_handler%';
update driver_fns set is_core=1, cloc=1, is_intr=1 where name like '%InterruptHandler%';

update driver_fns set is_core=1, cloc=1 where name like '%_send_frame' and
class ='bluetooth';
update driver_fns set is_core=1, cloc=1 where name like '%_flush' and
class='bluetooth';

delete from driver_fns where name like '%kmalloc%';
delete from driver_fns where name like '_memcpy';
delete from driver_fns where name like '__constant_memcpy';
delete from driver_fns where name like 'kmem%';
delete from driver_fns where name like 'get_current';
delete from driver_fns where name like '%kzalloc%';
delete from driver_fns where name like '%skb%';
delete from driver_fns where name like '%INIT_LIST_HEAD%';
delete from driver_fns where name like '%sglist%';
delete from driver_fns where name like '%kmalloc%';
delete from driver_fns where name like '%kmalloc%';
delete from driver_fns where name like '__rcu%';
delete from driver_fns where name like '%kobject%';
delete from driver_fns where name like '%netdev_get_tx_queue%';
delete from driver_fns where name like '%kmalloc%';  
delete from driver_fns where name like 'spin_lock%';
delete from driver_fns where name like '__raw_spin_%';
delete from driver_fns where name like '__raw_write_unlock_irq_%';
delete from driver_fns where name like 'spin_unlock%';
delete from driver_fns where name like '%netif_tx_%';
delete from driver_fns where name like 'valid_dma_direction';
delete from driver_fns where name like 'kcalloc';
delete from driver_fns where name like 'ioremap';
delete from driver_fns where name like "request_irq";
delete from driver_fns where name like "napi_enable";
delete from driver_fns where name like "inb_p";
delete from driver_fns where name like "__writel%";
delete from driver_fns where name like "__memcpy";
delete from driver_fns where name like "inb_p";
delete from driver_fns where name like "trace_module_get";
delete from driver_fns where name like "arch_spin_unlock";
delete from driver_fns where name like "do_raw_spin_unlock";
delete from driver_fns where name like "__init_work";
delete from driver_fns where name like "variable_test_bit";
delete from driver_fns where name like "signal_pending";
delete from driver_fns where name like "__create_pipe";
delete from driver_fns where name like "ERR_PTR";
delete from driver_fns where name like "inb_p";
delete from driver_fns where name like "inb_p";
delete from driver_fns where name like "outb_p";
delete from driver_fns where name like 'raw_irqs_disabled_flags';
delete from driver_fns where name like '%raw_local_%';
delete from driver_fns where name like 'pci_%_drvdata';
delete from driver_fns where name like 'test_ti_thread_flag';
delete from driver_fns where name like 'test_tsk_thread_flag';
delete from driver_fns where name like 'is_device_dma_capable';
delete from driver_fns where name like 'netif_stop_queue';
delete from driver_fns where name like 'might_fault';
delete from driver_fns where name like 'netif_wake_queue';
delete from driver_fns where name like 'netif_start_queue';
delete from driver_fns where name like 'input_sync';
delete from driver_fns where name like 'netif_running';
delete from driver_fns where name like 'module_is_live';
delete from driver_fns where name like 'slow_down_io';
delete from driver_fns where name like 'init_completion';
delete from driver_fns where name like 'poll_wait';
delete from driver_fns where name like 'is_multicast_ether_addr';
delete from driver_fns where name like '__set_bit';
delete from driver_fns where name like 'atomic_dec_and_test';
delete from driver_fns where name like 'is_zero_ether_addr';
delete from driver_fns where name like 'sg_page';
delete from driver_fns where name like 'ffs';
delete from driver_fns where name like 'iminor';
delete from driver_fns where name like 'tasklet_schedule';


delete from driver_fns where name like 'pci_%';
delete from driver_fns where name like '__readl';
delete from driver_fns where name like '__readw';
delete from driver_fns where name like 'test_and_%_bit';
delete from driver_fns where name like 'pfn_to_nid';
delete from driver_fns where name like '_%swab%';
delete from driver_fns where name like 'dma_%';
delete from driver_fns where name like 'copy_from_user';
delete from driver_fns where name like 'dev_name';
delete from driver_fns where name like 'dma_free_coherent';
delete from driver_fns where name like 'dma_free_coherent';
delete from driver_fns where name like '%list_add%';
delete from driver_fns where name like '%list_del%';
delete from driver_fns where name like 'list_empty';
delete from driver_fns where name like 'get_dma_ops';
delete from driver_fns where name like 'netdev_priv';
delete from driver_fns where name like 'memcpy';
delete from driver_fns where name like 'IS_ERR';
delete from driver_fns where name like 'atomic_read';
delete from driver_fns where name like 'get_order';
delete from driver_fns where name like 'set_bit';
delete from driver_fns where name like 'test_and_set_bit';
delete from driver_fns where name IN ('inb', 'outb', 'inl', 'outl', 'readb',
    'writeb', 'kmemleak_alloc', 'atoh', 'readl', 'writel', 'atomic_inc',
    'PTR_ERR', 'get_page', 'clear_bit', 'spinlock_check', '__constant_c_memset',
     '__constant_c_and_count_memset', 'atomic_dec', 'atomic_inc', 'inw', 'outw', 
    'current_thread_info', 'constant_test_bit', 'list_del', 'atomic_set',
    'prefetch', 'readw', 'writew');


update drivers set basic_type = 'char' where class in ('char','serial', 'video',
    'led', 'bluetooth', 'gpio', 'pcmcia', 'firewire', 'isdn', 'tty', 'gpu',
    'sound', 'thermal', 'acpi', 'input', 'auxdisplay', 'watchdog', 'telephony',
    'parport', 'misc', 'ieee1394', 'pps', 'spi','led' ,'media', 'accessibility',
    'rtc', 'leds', 'hwmon', 'w1', 'uio', 'cpufreq', 'edac', 'regulator', 'power',
    'clocksource', 'connector' , 'platform', 'hid', 'cpuidle', 'dca', 'message',
    'macintosh', 'pnp', 'char', 'crypto' );

update drivers set basic_type = 'block' where class in ('ata', 'cdrom',
    'floppy', 'scsi' , 'ide', 'parport', 'block', 'md', 'mtd' , 'mmc', 'ssb',
    'mfd', 'memstick');

update drivers set basic_type = 'net' where class in ('net', 'infiniband',
    'uwb', 'atm', 'ieee802154');


update drivers set basic_type = 'block' where name like '%storage%';

update drivers set driver_types='core' where path like '%core%';

update drivers set driver_types='scsi_core' where name like '%scsi_%';

update drivers set driver_types='acpi_core' where class='acpi';

update driver_fns set is_core=1 where name like '%start_xmit';
update driver_fns set is_core=1 where name like '%execute%';
update driver_fns set is_init=1 where name like '%init%';
update driver_fns set is_init=1 where name like '%probe';
update driver_fns set is_dma=1 where name like '%dma%';
update driver_fns set dma_count=1 where name like '%dma%' and dma_count<1;
update driver_fns set is_cleanup=1 where name like '%exit%';
update driver_fns set cloc=1 where name like '%init_module%';
update driver_fns set cloc=1 where name like '%module_init%';
update driver_fns set cloc=1 where name like '%module_exit%';
update driver_fns set cloc=1 where name like '%exit_module%';




alter table driver_fns add column is_unique int;

update driver_fns set is_unique = is_init + is_cleanup + is_intr + is_config +
is_err + is_proc + is_pm + is_core + is_ioctl + is_devctl;

update driver_fns set is_unique=0 where is_unique > 1 ; 

update driver_fns set is_core=0 where is_init=1 and name like '%init%';

update drivers set class='scsi' where class='usb' and path like '%storage%';
update driver_fns set class='scsi' where driverid IN (select driverid from
    drivers where class='scsi' and path like '%usb%');
update drivers set class='serial' where class='usb' and path like '%serial%';
update driver_fns set class='serial' where driverid IN (select driverid from
    drivers where class='serial' and path like '%usb%');
-- XEN
update driver_fns set cloc=1 where name in ('network_open',
    'network_start_xmit', 'network_close', 'network_get_stats',
    'network_set_multicast_list', 'netif_uninit', 'xennet_set_mac_address', 
   'xennet_change_mtu') and class='xen'; 

-- mysql> update drivers set bus_type = 'spi_device_id' where driver_types like
-- 'spi%' and bus_type='empty_bus_type';
-- select bus_type, path from drivers  where driverid IN (select driverid from
    -- driver_fns where name like '%pci_%') and bus_type='empty_bus_type';
-- uery OK, 26 rows affected (1.18 sec)
-- Rows matched: 26  Changed: 26  Warnings: 0
--
-- mysql> select bus_type, path from drivers  where driverid IN (select driverid
    -- from driver_fns where name like 'i2c_%') and bus_type='empty_bus_type';
-- Empty set (0.53 sec)
--
-- mysql> update drivers  set bus_type='pcmcia_device_id' where driverid IN
-- (select driverid from driver_fns where name like 'pcmcia_%') and
-- bus_type='empty_bus_type';
-- Query OK, 7 rows affected (1.35 sec)
-- Rows matched: 7  Changed: 7  Warnings: 0
--
-- mysql> select bus_type, path from drivers  where driverid IN (select driverid
    -- from driver_fns where name like 'iee1394_%') and
-- bus_type='empty_bus_type';
-- Empty set (0.54 sec)
--
-- mysql> select bus_type, path from drivers  where driverid IN (select driverid
    -- from driver_fns where name like 'ieee1394_%') and
-- bus_type='empty_bus_type';
-- Empty set (0.52 sec)
--
-- mysql> select bus_type, path from drivers  where driverid IN (select driverid
    -- from driver_fns where name like 'memstick_%') and
-- bus_type='empty_bus_type';
-- +----------------+----------------------------------+
-- | bus_type       | path                             |
-- +----------------+----------------------------------+
-- | empty_bus_type | drivers/memstick/core/memstick.o | 
-- | empty_bus_type | drivers/memstick/host/tifm_ms.o  | 
-- +----------------+----------------------------------+
-- 2 rows in set (0.52 sec)
--
-- mysql> update drivers  set bus_type='memstick_device_id' where driverid IN
-- (select driverid from driver_fns where name like 'memstick_%') and
-- bus_type='empty_bus_type';
-- Query OK, 2 rows affected (1.27 sec)
-- Rows matched: 2  Changed: 2  Warnings: 0
--
-- mysql> select bus_type, path from drivers  where driverid IN (select driverid
    -- from driver_fns where name like 'serio_%') and bus_type='empty_bus_type';
-- +----------------+----------------------------------+
-- | bus_type       | path                             |
-- +----------------+----------------------------------+
-- | empty_bus_type | drivers/input/serio/serio.o      | 
-- | empty_bus_type | drivers/input/serio/serport.o    | 
-- | empty_bus_type | drivers/input/serio/parkbd.o     | 
-- | empty_bus_type | drivers/input/serio/ct82c710.o   | 
-- | empty_bus_type | drivers/input/serio/libps2.o     | 
-- | empty_bus_type | drivers/input/serio/altera_ps2.o | 
-- +----------------+----------------------------------+
-- 6 rows in set (0.52 sec)
--
-- mysql> update drivers  set bus_type='serio_device_id' where driverid IN
-- (select driverid from driver_fns where name like 'serio_%') and
-- bus_type='empty_bus_type';
-- Query OK, 6 rows affected (1.28 sec)
-- Rows matched: 6  Changed: 6  Warnings: 0
--
-- mysql> select bus_type, path from drivers  where driverid IN (select driverid
    -- from driver_fns where name like 'xenbus_%') and
-- bus_type='empty_bus_type';
-- Empty set (0.52 sec)
--
-- mysql> select bus_type, path from drivers  where driverid IN (select driverid
    -- from driver_fns where name like 'ssb_%') and bus_type='empty_bus_type';
-- mysql>  update drivers  set bus_type='pci_device_id' where driverid IN
-- (select driverid from driver_fns where name like 'pci_%') and
-- bus_type='empty_bus_type';
-- Query OK, 0 rows affected (1.68 sec)
-- Rows matched: 0  Changed: 0  Warnings: 0
--
-- mysql> update drivers set bus_type='platform_device_id' where driver_types
-- ='platform_driver';
-- Query OK, 56 rows affected (0.04 sec)
-- Rows matched: 202  Changed: 56  Warnings: 0
--
-- mysql>  update drivers  set bus_type='usb_device_id' where driverid IN
-- (select driverid from driver_fns where name like 'usb_%') and
-- bus_type='empty_bus_type';
-- Query OK, 31 rows affected (1.52 sec)
-- Rows matched: 31  Changed: 31  Warnings: 0
--   update drivers  set bus_type='i2c_device_id' where driverid IN (select
    --   driverid from driver_fns where name like 'i2c_%') and
--   bus_type='empty_bus_type';
--   Query OK, 27 rows affected (1.56 sec)
--   Rows matched: 27  Changed: 27  Warnings: 0
--
--

 update driver_fns set cloc=1 where name like '%power%' and name not like
'%power_of_%' and class='leds';

 update driver_fns set cloc=1 where name like '%led_brightness%' and
class='leds';

 update driver_fns set cloc=1 where name like '%ioctl%' and class='leds';


update driver_fns set cloc=1 where name like '%activate%' and class='leds';

 update driver_fns set cloc=1 where name like '%dectivate%' and class='leds';

update driver_fns set cloc=1 where name like '%deactivate%' and class='leds';

 update driver_fns set is_core=1, cloc=1 where name like '%deactivate%' and
class='leds';

 update driver_fns set is_core=1, cloc=1 where name like '%activate%' and
class='leds';


create table if not exists correlation  select driver_fns.driverid,
ROUND(100*sum(loc*is_init)/sum(loc),2) init, (select chipset from drivers where
    driver_fns.driverid=driverid) chip from driver_fns group by
driver_fns.driverid order by 3;

SELECT @n := COUNT(init) AS N, @meanX := AVG(chip) AS "X mean", @sumX :=
SUM(chip) AS "X sum",@sumXX := SUM(chip*chip) "X sum of squares", @meanY :=
AVG(init) AS "Y mean",  @sumY := SUM(init) AS "Y sum", @sumYY := SUM(init*init)
"Y sum of square", @sumXY := SUM(chip*init) AS "X*Y sum" FROM correlation;


SELECT (@n*@sumXY - @sumX*@sumY) / SQRT((@n*@sumXX - @sumX*@sumX) * (@n*@sumYY -
        @sumY*@sumY)) AS corr; 


alter table driver_fns add column driver_types varchar(40);
alter table driver_fns add column bus_type varchar(30);

update driver_fns set bus_type = (select bus_type from drivers where
    driver_fns.driverid=drivers.driverid);
update driver_fns set driver_types = (select driver_types from drivers where
    driver_fns.driverid=drivers.driverid);
