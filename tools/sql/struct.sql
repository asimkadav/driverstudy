-- phpMyAdmin SQL Dump
-- version 2.11.10.1
-- http://www.phpmyadmin.net
--
-- Host: mysql.cs.wisc.edu:3306
-- Generation Time: Jul 20, 2011 at 12:09 AM
-- Server version: 5.0.77
-- PHP Version: 5.3.6

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `driverstudy`
--

-- --------------------------------------------------------

--
-- Table structure for table `callgraph`
--

DROP TABLE IF EXISTS `callgraph`;
CREATE TABLE IF NOT EXISTS `callgraph` (
  `driverid` int(11) NOT NULL,
  `calller` varchar(30) NOT NULL,
  `callee` varchar(30) NOT NULL,
  KEY `driverid` (`driverid`),
  FULLTEXT KEY `callee` (`callee`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `drivers`
--

DROP TABLE IF EXISTS `drivers`;
CREATE TABLE IF NOT EXISTS `drivers` (
  `driverid` int(11) NOT NULL auto_increment,
  `name` text NOT NULL,
  `path` text NOT NULL,
  `class` text NOT NULL,
  `subclass` varchar(50) NOT NULL,
  `loc` int(11) NOT NULL,
  `chipset` int(11) NOT NULL,
  `has_recovery` int(11) NOT NULL,
  `driver_types` varchar(40) NOT NULL,
  `driver_ops` varchar(40) NOT NULL,
  `basic_type` varchar(40) NOT NULL,
  `bfactor` int(11) NOT NULL,
  `cfactor` int(11) NOT NULL,
  `bus_type` varchar(30) NOT NULL,
  PRIMARY KEY  (`driverid`),
  UNIQUE KEY `driverid` (`driverid`),
  KEY `driverid_2` (`driverid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1820 ;

-- --------------------------------------------------------

--
-- Table structure for table `drivers_26188`
--

DROP TABLE IF EXISTS `drivers_26188`;
CREATE TABLE IF NOT EXISTS `drivers_26188` (
  `driverid` int(11) NOT NULL auto_increment,
  `name` text NOT NULL,
  `path` text NOT NULL,
  `class` text NOT NULL,
  `loc` int(11) NOT NULL,
  `chipset` int(11) NOT NULL,
  `has_recovery` int(11) NOT NULL,
  `driver_types` varchar(40) NOT NULL,
  `driver_ops` varchar(40) NOT NULL,
  `basic_type` varchar(40) NOT NULL,
  `bfactor` int(11) NOT NULL,
  `cfactor` int(11) NOT NULL,
  `bus_type` varchar(30) NOT NULL,
  PRIMARY KEY  (`driverid`),
  UNIQUE KEY `driverid` (`driverid`),
  KEY `driverid_2` (`driverid`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1214 ;

-- --------------------------------------------------------

--
-- Table structure for table `driver_fns`
--

DROP TABLE IF EXISTS `driver_fns`;
CREATE TABLE IF NOT EXISTS `driver_fns` (
  `driverid` int(11) NOT NULL,
  `name` text NOT NULL,
  `class` varchar(20) NOT NULL,
  `subclass` varchar(50) NOT NULL,
  `loc` int(11) NOT NULL,
  `cloc` int(11) NOT NULL COMMENT 'Cumulative LOC',
  `is_ioctl` tinyint(1) NOT NULL,
  `is_init` tinyint(1) NOT NULL,
  `is_cleanup` tinyint(1) NOT NULL,
  `is_pm` tinyint(1) NOT NULL,
  `is_err` tinyint(1) NOT NULL,
  `is_config` tinyint(1) NOT NULL,
  `is_proc` int(11) NOT NULL,
  `is_modpm` tinyint(1) NOT NULL,
  `is_devctl` smallint(6) NOT NULL COMMENT 'Device control',
  `ttd` int(11) NOT NULL,
  `ttk` int(11) NOT NULL,
  `is_allocator` int(11) NOT NULL,
  `is_core` smallint(6) NOT NULL,
  `is_sync` tinyint(4) NOT NULL,
  `is_process` tinyint(4) NOT NULL,
  `is_event` tinyint(4) NOT NULL,
  `is_thread` tinyint(4) NOT NULL,
  `is_dma` tinyint(4) NOT NULL,
  `is_bus` tinyint(4) NOT NULL,
  `dev_call_count` tinyint(4) NOT NULL,
  `sync_call_count` tinyint(4) NOT NULL,
  `mem_call_count` smallint(100) NOT NULL,
  `ttk_count` mediumint(9) NOT NULL,
  `is_port` mediumint(9) NOT NULL,
  `is_mmio` smallint(6) NOT NULL,
  `is_intr` tinyint(4) NOT NULL,
  `is_kernlib` tinyint(4) NOT NULL,
  `is_kerndev` tinyint(4) NOT NULL,
  `is_devreg` tinyint(4) NOT NULL,
  `is_time` tinyint(4) NOT NULL,
  `dma_count` mediumint(9) NOT NULL,
  `bus_count` mediumint(9) NOT NULL,
  `portmm_count` mediumint(9) NOT NULL,
  `kdev_count` mediumint(9) NOT NULL,
  `klib_count` mediumint(9) NOT NULL,
  FULLTEXT KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `driver_fns_26188`
--

DROP TABLE IF EXISTS `driver_fns_26188`;
CREATE TABLE IF NOT EXISTS `driver_fns_26188` (
  `driverid` int(11) NOT NULL,
  `name` text NOT NULL,
  `class` varchar(20) NOT NULL,
  `loc` int(11) NOT NULL,
  `cloc` int(11) NOT NULL COMMENT 'Cumulative LOC',
  `is_ioctl` tinyint(1) NOT NULL,
  `is_init` tinyint(1) NOT NULL,
  `is_cleanup` tinyint(1) NOT NULL,
  `is_pm` tinyint(1) NOT NULL,
  `is_err` tinyint(1) NOT NULL,
  `is_config` tinyint(1) NOT NULL,
  `is_proc` int(11) NOT NULL,
  `is_modpm` tinyint(1) NOT NULL,
  `is_devctl` smallint(6) NOT NULL COMMENT 'Device control',
  `ttd` int(11) NOT NULL,
  `ttk` int(11) NOT NULL,
  `is_allocator` int(11) NOT NULL,
  `is_core` smallint(6) NOT NULL,
  `is_sync` tinyint(4) NOT NULL,
  `is_process` tinyint(4) NOT NULL,
  FULLTEXT KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `driver_ops`
--

DROP TABLE IF EXISTS `driver_ops`;
CREATE TABLE IF NOT EXISTS `driver_ops` (
  `opsid` tinyint(4) NOT NULL auto_increment,
  `name` varchar(20) NOT NULL,
  `desc` varchar(50) NOT NULL,
  `class` varchar(20) NOT NULL,
  PRIMARY KEY  (`opsid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `driver_types`
--

DROP TABLE IF EXISTS `driver_types`;
CREATE TABLE IF NOT EXISTS `driver_types` (
  `opsid` tinyint(10) NOT NULL auto_increment,
  `name` varchar(25) NOT NULL,
  `desc` varchar(25) NOT NULL,
  PRIMARY KEY  (`opsid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=6 ;

-- --------------------------------------------------------

--
-- Table structure for table `legend`
--

DROP TABLE IF EXISTS `legend`;
CREATE TABLE IF NOT EXISTS `legend` (
  `name` text NOT NULL,
  `desc` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
