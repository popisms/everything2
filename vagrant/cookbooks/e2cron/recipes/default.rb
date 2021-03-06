#
# Cookbook Name:: e2cron
# Recipe:: default
#
# Copyright 2012, Everything2 Media LLC
#
# You are free to use/modify these files under the same terms as the Everything Engine itself
#

# Also in e2engine,e2web,e2tls
logdir = "/var/log/everything"
datelog = "`date +\\%Y\\%m\\%d\\%H`.log"

directory logdir do
  owner "www-data"
  group "root"
  mode 0755
  action :create
end

cron 'log_deliver_to_s3.pl' do
  minute '5'
  command "/var/everything/tools/log_deliver_to_s3.pl 2>&1 >> #{logdir}/e2cron.log_deliver_to_s3.#{datelog}"
end

cron 'database_backup_to_s3.pl' do
  hour "0"
  minute "2"
  command "/var/everything/tools/database_backup_to_s3.pl 2>&1 >> #{logdir}/e2cron.database_backup_to_s3.#{datelog}" 
end

cron 'generate_sitemap.pl' do
  hour "1"
  minute "0"
  command "/var/everything/tools/generate_sitemap.pl 2>&1 >> #{logdir}/e2cron.generate_sitemap.#{datelog}"
end

cron 'updateNodelet.pl' do
  user "root"
  minute "0-59/5"
  command "/var/everything/tools/updateNodelet.pl 2>&1 >> #{logdir}/e2cron.updateNodelet.#{datelog}"
end

cron 'refreshRoom.pl' do
  user "root"
  minute "0-59/5"
  command "/var/everything/tools/refreshRoom.pl 2>&1 >> #{logdir}/e2cron.refreshRoom.#{datelog}"
end

cron 'cleanCbox.pl' do
  user "root"
  minute "50"
  command "/var/everything/tools/cleanCbox.pl 2>&1 >> #{logdir}/e2cron.cleanCbox.#{datelog}"
end

cron 'newstats.pl' do
  user "root"
  minute "10"
  hour "6"
  command "/var/everything/tools/newstats.pl 2>&1 >> #{logdir}/e2cron.newstats.#{datelog}"
end

cron 'expirerooms.pl' do
  user "root"
  minute "30"
  hour "6"
  command "/var/everything/tools/expirerooms.pl 2>&1 >> #{logdir}/e2cron.expirerooms.#{datelog}"
end

cron 'reaper.pl' do
  user "root"
  minute "50"
  hour "6"
  command "/var/everything/tools/reaper.pl 2>&1 >> #{logdir}/e2cron.reaper.#{datelog}"
end

cron 'data_generator_heartbeat.pl' do
  user "root"
  command "/var/everything/tools/data_generator_heartbeat.pl 2>&1 >> #{logdir}/data_generator_heartbeat.reaper.#{datelog}"
end

# We need this on the bastion. Place a 1g swapfile in the root dir
#
bash 'createswap' do
  creates "/swapfile"
  code "
    dd if=/dev/zero of=/swapfile bs=1024 count=1M
    mkswap /swapfile
    swapon /swapfile
  "
end
