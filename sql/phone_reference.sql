CREATE TABLE `phone_reference` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(12) NOT NULL DEFAULT '',
  `phone` BIGINT(11) UNSIGNED DEFAULT '0',
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `phone_i` (`phone`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;