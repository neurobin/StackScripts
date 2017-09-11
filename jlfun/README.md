
This script does not do anything on its own. Does not deploy directly.

This is a collection of useful bash functions to be included in other bash StackScripts with a "source <ssinclude StackScriptID=182722>" line.

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

## system_update

* upgrade the system

## system_get_install_command

* get package manager install command

## system_get_primary_ip

* returns the primary IP assigned to a network interface
* `$1` - Required - network interface, default: eth0

## system_get_rdns

* calls host on an IP address and returns its reverse dns
* `$1` - Required - ip address

## system_get_rdns_primary_ip

* returns the reverse dns of the primary IP assigned to this system
* `$1` - Required - Network interface, default: eth0

## system_set_hostname

* `$1` - Required - The hostname to define

## system_add_host_entry

* `$1` - Required - The IP address to set a hosts entry for
* `$2` - Required - The FQDN to set to the IP

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

## fail2ban_start

* start and enable fail2ban

## fail2ban_restart

* restart fail2ban

## fail2ban_install

* install **fail2ban**

## ufw_restart

* restart ufw

## ufw_start

* start and enable ufw

## ufw_allow_commons

* allow common service ports

## ufw_install

* install **ufw** (debian, ubuntu, and archlinux)

## user_add_with_sudo

* Installs sudo if needed and creates a user in the sudo group.
* `$1` - Required - username
* `$2` - Required - password
* `$3` - Optional - shell

## common_install

* Install some common packages: git, wget, bc, tar, gzip, lzip inxi

## colorful_bash_prompt_install

* Install a colorful bash prompt

## sendmail_start

* Start sendmail service

## sendmail_restart

* Restart sendmail service

## sendmail_install

* Install and start **sendmail** service

## apache2_start

* start apache2

## apache2_restart

* restart apache2

## apache2_install

* installs the system default **apache2**

## apache2_tune

* Tunes Apache's memory to use the percentage of RAM you specify, defaulting to 40%
* $1 - the percent of system memory to allocate towards Apache

## apache2_tune_with_defaults

* Tune apache2 according to linode ram size

## mysql_start

* start mysql service

## mysql_restart

* restart mysql service

## mysql_install

* Install **mysql** and secure it with `mysql_secure_installation` (Debian/Ubuntu)
* `$1` - the mysql root password

## mysql_tune

* Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%
* `$1` - the percent of system memory to allocate towards MySQL

## mysql_tune_with_defaults

* Tune mysql according to linode RAM size
