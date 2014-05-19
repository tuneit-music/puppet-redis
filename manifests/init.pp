# == Class: redis
#
# Install redis.
#
# === Parameters
#
# [*version*]
#   Version to install.
#   Default: 2.8.3
#
# [*redis_src_dir*]
#   Location to unpack source code before building and installing it.
#   Default: /opt/redis-src
#
# [*redis_bin_dir*]
#   Location to install redis binaries.
#   Default: /opt/redis
#
# [*redis_port*]
#   Accept redis connections on this port.
#   Default: 6379
#
# [*redis_bind_address*]
#   Address to bind to.
#   Default: false, which binds to all interfaces
#
# [*redis_max_memory*]
#   Maximum memory to be addressed by instance
#   Default: 4gb
#
# [*redis_max_clients*]
#   Set the redis config value maxclients. If no value provided, it is
#   not included in the configuration for 2.6+ and set to 0 (unlimited)
#   for 2.4.
#   Default: 0 (2.4)
#   Default: nil (2.6+)
#
# [*redis_timeout*]
#   Set the redis config value timeout (seconds).
#   Default: 300
#
# [*redis_loglevel*]
#   Set the redis config value loglevel. Valid values are debug,
#   verbose, notice, and warning.
#   Default: notice
#
# [*redis_databases*]
#   Set the redis config value databases.
#   Default: 16
#
# [*redis_slowlog_log_slower_than*]
#   Set the redis config value slowlog-log-slower-than (microseconds).
#   Default: 10000
#
# [*redis_showlog_max_len*]
#   Set the redis config value slowlog-max-len.
#   Default: 1024
#
# [*redis_password*]
#   Password used by AUTH command. Will be set if its not nil.
#   Default: nil
#
# [*redis_is_slave*]
#   Specify whether instance is a slave.
#   Default: false
#
# [*redis_slaveof_master_ip*]
#   IP address of master instance that this slave replicates.
#   Default: localhost
#
# [*redis_slaveof_master_port*]
#   Port that master instance is listening on.
#   Default: 6379
#
# [*redis_slave_priority*]
#   Used by Redis Sentinel to select a slave to promote to master.
#   A slave with a low priority number is considered better for promotion.
#   However a special priority of 0 marks the slave as not able to perform
#   the role of master.
#   Default: 100
#
# [*redis_masterauth_password*]
#
#   If the master is password protected (using the "requirepass" configuration
#   directive below) it is possible to tell the slave to authenticate before
#   starting the replication synchronization process, otherwise the master will
#   refuse the slave request.
#
# === Examples
#
# include redis
#
# class { 'redis':
#   version       => '2.8',
#   redis_src_dir => '/fake/path/redis-src',
#   redis_bin_dir => '/fake/path/redis',
# }
#
# === Authors
#
# Thomas Van Doren
#
# === Copyright
#
# Copyright 2012 Thomas Van Doren, unless otherwise noted.
#
class redis (
  $version = $redis::params::version,
  $redis_src_dir = $redis::params::redis_src_dir,
  $redis_bin_dir = $redis::params::redis_bin_dir,
  $redis_port = $redis::params::redis_port,
  $redis_bind_address = $redis::params::redis_bind_address,
  $redis_max_memory = $redis::params::redis_max_memory,
  $redis_max_clients = $redis::params::redis_max_clients,
  $redis_timeout = $redis::params::redis_timeout,
  $redis_loglevel = $redis::params::redis_loglevel,
  $redis_databases = $redis::params::redis_databases,
  $redis_slowlog_log_slower_than = $redis::params::redis_slowlog_log_slower_than,
  $redis_slowlog_max_len = $redis::params::redis_slowlog_max_len,
  $redis_password = $redis::params::redis_password,
  $redis_is_slave = $redis::params::redis_is_slave,
  $redis_slaveof_master_ip = $redis::params::redis_slaveof_master_ip,
  $redis_slaveof_master_port = $redis::params::redis_slaveof_master_port,
  $redis_slave_priority = $redis::params::redis_slave_priority,
  $redis_masterauth_password = $redis::params::redis_masterauth_password
) inherits redis::params {

  include wget
  include gcc

  $redis_pkg_name = "redis-${version}.tar.gz"
  $redis_pkg = "${redis_src_dir}/${redis_pkg_name}"

  # Install default instance
  redis::instance { 'redis-default':
     redis_port                    => $redis_port,
     redis_bind_address            => $redis_bind_address,
     redis_max_memory              => $redis_max_memory,
     redis_max_clients             => $redis_max_clients,
     redis_timeout                 => $redis_timeout,
     redis_loglevel                => $redis_loglevel,
     redis_databases               => $redis_databases,
     redis_slowlog_log_slower_than => $redis_slowlog_log_slower_than,
     redis_slowlog_max_len         => $redis_slowlog_max_len,
     redis_password                => $redis_password,
     redis_is_slave                => $redis_is_slave,
     redis_slaveof_master_ip       => $redis_slaveof_master_ip,
     redis_slaveof_master_port     => $redis_slaveof_master_port,
     redis_slave_priority          => $redis_slave_priority,
     redis_masterauth_password     => $redis_masterauth_password,
 }

  group { 'redis':
    ensure => present,
  }

  user { 'redis':
    ensure => present,
    gid => "redis",
    require => Group["redis"],
  }

  File {
    owner => redis,
    group => redis,
    require => User["redis"],
  }
  file { $redis_src_dir:
    ensure => directory,
  }
  file { '/etc/redis':
    ensure => directory,
  }
  file { 'redis-lib':
    ensure => directory,
    path   => '/var/lib/redis',
  }
  file { 'redis-pid':
    ensure => directory,
    path   => '/var/run/redis',
  }
  file { 'redis-log-dir':
    ensure => directory,
    path   => '/var/log/redis',
  }

  exec { 'get-redis-pkg':
    command => "/usr/bin/wget --output-document ${redis_pkg} http://download.redis.io/releases/${redis_pkg_name}",
    unless  => "/usr/bin/test -f ${redis_pkg}",
    require => File[$redis_src_dir],
  }

  file { 'redis-cli-link':
    ensure => link,
    path   => '/usr/local/bin/redis-cli',
    target => "${redis_bin_dir}/bin/redis-cli",
  }
  exec { 'unpack-redis':
    command => "tar --strip-components 1 -xzf ${redis_pkg}",
    cwd     => $redis_src_dir,
    path    => '/bin:/usr/bin',
    unless  => "test -f ${redis_src_dir}/Makefile",
    require => Exec['get-redis-pkg'],
  }
  exec { 'install-redis':
    command => "make && make install PREFIX=${redis_bin_dir}",
    cwd     => $redis_src_dir,
    path    => '/bin:/usr/bin',
    unless  => "test $(${redis_bin_dir}/bin/redis-server --version | cut -d ' ' -f 1) = 'Redis'",
    require => [ Exec['unpack-redis'], Class['gcc'] ],
  }

}
