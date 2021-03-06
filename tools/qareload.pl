#!/usr/bin/perl -w

use strict;
use lib qw(/var/everything/ecore);
use Everything;

if($Everything::CONF->environment ne "development")
{
	print "Not in the 'development' environment. Exiting\n";
	exit;
}

`echo "drop database everything" | mysql -u root`;
`echo "create database everything" | mysql -u root`;
`/var/everything/ecoretool/ecoretool.pl bootstrap --nodepack=/var/everything/nodepack`;
`/var/everything/tools/seeds.pl`;
`/var/everything/tools/data_generator_heartbeat.pl`;
`/etc/init.d/apache2 restart`;
