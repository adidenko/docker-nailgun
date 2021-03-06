$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and $::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'dev'
}

if $production == 'prod'{
  $env_path = "/usr"
  $staticdir = "/usr/share/nailgun/static"
} else {
  $env_path = "/opt/nailgun"
  $staticdir = "/opt/nailgun/share/nailgun/static"
}

Class["nailgun::user"] ->
Class["nailgun::venv"]

package { "supervisor": }
package { "python-virtualenv": }
package { "python-devel": }
package { "postgresql-libs": }
package { "postgresql-devel": }
package { "ruby-devel": }
package { "gcc": }
package { "gcc-c++": }
package { "make": }
package { "rsyslog": }
package { "fence-agents": }
package { "nailgun-redhat-license": }
package { "python-fuelclient": }

Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

$centos_repos =
[
 {
 "id" => "nailgun",
 "name" => "Nailgun",
 "url"  => "\$tree"
 },
]

$repo_root = "/var/www/nailgun"
#$pip_repo = "/var/www/nailgun/eggs"
$pip_repo = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/eggs/"
$gem_source = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/"

$package = "Nailgun"
$version = "0.1.0"
$astute_version = "0.0.2"
$nailgun_group = "nailgun"
$nailgun_user = "nailgun"
$venv = $env_path

$pip_index = "--no-index"
$pip_find_links = "-f ${pip_repo}"

$templatedir = $staticdir

class { "nailgun::user":
  nailgun_group => $nailgun_group,
  nailgun_user => $nailgun_user,
}

class { "nailgun::venv":
  venv => $venv,
  venv_opts => "--system-site-packages",
  package => $package,
  version => $version,
  pip_opts => "${pip_index} ${pip_find_links}",
  production => $production,
  nailgun_user => $nailgun_user,
  nailgun_group => $nailgun_group,

  database_name => "nailgun",
  database_engine => "postgresql",
  database_host => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  database_port => "5432",
  database_user => "nailgun",
  database_passwd => "nailgun",

  staticdir => $staticdir,
  templatedir => $templatedir,
  rabbitmq_astute_user => $rabbitmq_astute_user,
  rabbitmq_astute_password => $rabbitmq_astute_password,

  admin_network         => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_cidr    => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_size    => ipcalc_network_count_addresses($::fuel_settings['ADMIN_NETWORK']['ipaddress'], $::fuel_settings['ADMIN_NETWORK']['netmask']),
  admin_network_first   => $::fuel_settings['ADMIN_NETWORK']['static_pool_start'],
  admin_network_last    => $::fuel_settings['ADMIN_NETWORK']['static_pool_end'],
  admin_network_netmask => $::fuel_settings['ADMIN_NETWORK']['netmask'],
  admin_network_ip      => $::fuel_settings['ADMIN_NETWORK']['ipaddress']

}
