-- MySQL dump 10.13  Distrib 5.7.24, for Linux (x86_64)
--
-- Host: localhost    Database: etherchain
-- ------------------------------------------------------
-- Server version	5.7.24-0ubuntu0.18.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `richlist`
--

DROP TABLE IF EXISTS `richlist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `richlist` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `address` char(42) DEFAULT NULL,
  `block` bigint(20) DEFAULT NULL,
  `firstIn` datetime DEFAULT NULL,
  `lastIn` datetime DEFAULT NULL,
  `firstOut` datetime DEFAULT NULL,
  `lastOut` datetime DEFAULT NULL,
  `numIn` int(11) DEFAULT NULL,
  `numOut` int(11) DEFAULT NULL,
  `value` double DEFAULT NULL,
  `needupdate` bigint(20) DEFAULT NULL,
  `updatecount` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `address` (`address`),
  KEY `address_idx` (`address`),
  KEY `needupdate` (`needupdate`),
  KEY `updatecount` (`updatecount`)
) ENGINE=InnoDB AUTO_INCREMENT=10683 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `transactions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `hash` char(66) DEFAULT NULL,
  `txhash` char(66) DEFAULT NULL,
  `block` bigint(20) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `fromaddr` char(42) DEFAULT NULL,
  `toaddr` char(42) DEFAULT NULL,
  `value` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_block` (`block`),
  KEY `idx_txhash` (`txhash`),
  KEY `idx_fromaddr` (`fromaddr`),
  KEY `idx_toaddr` (`toaddr`)
) ENGINE=InnoDB AUTO_INCREMENT=3944832 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-01-28 17:38:49
