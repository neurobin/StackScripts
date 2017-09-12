
This script does not do anything on its own. Does not deploy directly.

This is a collection of useful bash functions to be included in other bash StackScripts with a `source <ssinclude StackScriptID=182722>` line.

A tiny (experimental) effort is made to support different distros: Debian, Ubuntu, Archlinux, Gentoo, Fedora, Centos, Slackware

# Functions

The available functions are:

## msg_out

* Print message with backslash interpretation prepending with '*** '
* Prints on stdout
* All arguments are printed as a single space separated string.

## err_out

* Print error message with backslash interpretation prepending with 'E: '
* Prints on stderr
* All arguments are printed as a single space separated string.

## wrn_out

* Print warning message with backslash interpretation prepending with 'W: '
* Prints on stderr
* All arguments are printed as a single space separated string.

## err_exit

* Print error with err_out() and exit with 1 exit status
* Print error message with backslash interpretation prepending with 'E: '
* Prints on stderr
* All arguments are printed as a single space separated string.

## print_linode_info

* Show linode info

## chkcmd

* Check if a command is available
* `$1` - Required - command to check

## system_get_install_command

* Get package manager install command
* Overridable by defining INSTALL_COMMAND environment variable

## system_get_update_command

* Get package manager update command
* Overridable by defining UPDATE_COMMAND environment variable

## system_get_upgrade_command

* Get package manager upgrade command
* Overridable by defining UPGRADE_COMMAND environment variable

## system_get_os_family

* Get OS family name
* Overridable by defining OSS environment variable

## system_update

* update the system
* some os may perform total upgrade like archlinux, centos, fedora
* update command used may be overriden with UPDATE_COMMAND environment variable

## system_upgrade

* upgrade the system
* upgrade command used may be overriden with UPGRADE_COMMAND environment variable

## system_get_primary_ip

* returns the primary IP assigned to a network interface
* `$1` - Optional - network interface, default: eth0

## system_get_rdns

* calls host on an IP address and returns its reverse dns
* `$1` - Required - ip address

## system_get_rdns_primary_ip

* returns the reverse dns of the primary IP assigned to this system
* `$1` - Optional - Network interface, default: eth0

## system_set_hostname

* `$1` - Required - The hostname to define

## system_add_host_entry

* `$1` - Required - The IP address to set a hosts entry for
* `$2` - Required - The FQDN to set to the IP

## user_add_with_sudo

* Installs sudo if needed and creates a user in the sudo group.
* `$1` - Required - username
* `$2` - Required - password
* `$3` - Optional - shell

## ssh_start

* start ssh service

## ssh_restart

* restart ssh service

## ssh_user_add_pubkey

* Adds the users public key to authorized_keys for the specified user.
* Make sure you wrap your input variables in double quotes, or the key may not load properly.
* `$1` - Required - username
* `$2` - Required - public key

## ssh_disable_root_login

* Disables root SSH access.

## ssh_restrict_address_family

* `$1` - Required - Address family, inet for IPV4 and inet6 of IPV6

## fail2ban_get_package_names

* Get the packages names that will install fail2ban
* Overridable by defining FAIL2BAN_PACKS environment variable

## fail2ban_start

* start and enable fail2ban

## fail2ban_restart

* restart fail2ban

## fail2ban_install

* install **fail2ban**

## ufw_get_package_names

* Get the packages names that will install ufw
* Overridable by defining UFW_PACKS environment variable

## ufw_start

* start and enable ufw

## ufw_restart

* restart ufw

## ufw_allow_commons

* allow common service ports

## ufw_install

* install **ufw** (debian, ubuntu, and archlinux)

## common_install

* Install some common packages: git, wget, bc, tar, gzip, lzip inxi
* Overridable by defining COMMON_PACKS environment variable

## colorful_bash_prompt_install

* Install a colorful bash prompt
* .bashrc file: https://raw.githubusercontent.com/neurobin/DemoCode/master/bash/.bashrc

## sendmail_get_package_names

* Get the packages names that will install sendmail
* Overridable by defining SENDMAIL_PACKS environment variable

## sendmail_start

* Start sendmail service

## sendmail_restart

* Restart sendmail service

## sendmail_install

* Install and start **sendmail** service

## apache2_get_package_names

* Get the packages names that will install Apache2
* Overridable by defining APACHE2_PACKS environment variable

## apache2_start

* start apache2

## apache2_restart

* restart apache2

## apache2_install

* installs the system default **apache2**
* Package list overridable by defining APACHE2_PACKS environment variable
* Module list overridable by defining APACHE2_MODULES environment variable

## apache2_tune

* Tunes Apache's memory to use the percentage of RAM you specify, defaulting to 40%
* `$1` - the percent of system memory to allocate towards Apache

## apache2_tune_with_defaults

* Tune apache2 according to linode RAM size
* `$1` - the percent of system memory to allocate towards Apache (40)

## mysql_get_package_names

* Get the packages names that will install Apache2
* Overridable by defining APACHE2_PACKS environment variable

## mysql_start

* start mysql service

## mysql_restart

* restart mysql service

## mysql_install

* Install **mysql** (Debian/Ubuntu)
* `$1` - the mysql root password
* Package list overridable by defining MYSQL_PACKS environment variable

## mysql_tune_security

* Secure MySQL with `mysql_secure_installation`
* `$1` - the mysql root password

## mysql_tune

* Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%
* `$1` - Optional - the percent of system memory to allocate towards MySQL [40]

## mysql_tune_with_defaults

* Tune mysql according to linode RAM size
* `$1` - Optional - the percent of system memory to allocate towards MySQL [40]
