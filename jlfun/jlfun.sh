#!/bin/bash
# ##############################################################################
# ################################# JLFUN ######################################
# ##############################################################################
#
# Copyright (c) 2017 Md. Jahidul Hamid. All rights reserved.
# 
# -----------------------------------------------------------------------------
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
# 
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
# 
#     * The names of its contributors may not be used to endorse or promote 
#       products derived from this software without specific prior written
#       permission.
#       
# Disclaimer:
# 
#     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#     AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#     IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#     ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#     LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#     CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#     SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#     INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#     CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#     ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#     POSSIBILITY OF SUCH DAMAGE.
# ##############################################################################

################################## HELP ########################################
# Environment Variable  Description
# LINODE_ID             The Linode's ID number (123456)
# LINODE_LISHUSERNAME   The Linode's full lish-accessible name (linode123456)
# LINODE_RAM            The RAM available on this Linode's plan (1024)
# LINODE_DATACENTERID   The ID number of the data center containing the Linode (6)
################################################################################

################################################################################
# Message printing functions
################################################################################

msg_out(){
    # * Print message with backslash interpretation prepending with '*** '
    # * Prints on stdout
    # * All arguments are printed as a single space separated string.
	printf '\n%b\n' "*** $*"
}

err_out(){
    # * Print error message with backslash interpretation prepending with 'E: '
    # * Prints on stderr
    # * All arguments are printed as a single space separated string.
	printf '\n%b\n' "E: $*" >&2
}

wrn_out(){
    # * Print warning message with backslash interpretation prepending with 'W: '
    # * Prints on stderr
    # * All arguments are printed as a single space separated string.
	printf '\n%b\n' "W: $*" >&2
}

err_exit(){
    # * Print error with err_out() and exit with 1 exit status
    # * Print error message with backslash interpretation prepending with 'E: '
    # * Prints on stderr
    # * All arguments are printed as a single space separated string.
	err_out "$*"
	exit 1
}

print_linode_info(){
    # * Show linode info
    echo "
    Linode ID:              $LINODE_ID
    Linode data center ID:  $LINODE_DATACENTERID
    Lish username:          $LINODE_LISHUSERNAME
    Linode RAM:             $LINODE_RAM
    "
}


################################################################################
# Checks
################################################################################

chkcmd(){
    # * Check if a command is available
    # * `$1` - Required - command to check
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Compatibility layer
################################################################################

oss=(Unknown Debian Centos Fedora Archlinux Gentoo Slackware)
install_command=('false' 'apt-get install -y' 'yum install -y' 'dnf -y install' 'pacman -S' 'emerge' 'slackpkg install')
update_command=('false' 'apt-get update' 'yum -y update' 'dnf -y upgrade' 'pacman -Syu' 'emaint sync' 'slackpkg update')
upgrade_command=('false' 'apt-get -y dist-upgrade' 'true' 'true' 'true' 'emerge --uDN @world' 'slackpkg upgrade-all')
fail2ban_packs=('false' 'fail2ban sendmail-bin sendmail' 'epel-release fail2ban sendmail' 'fail2ban sendmail' 'fail2ban sendmail' 'fail2ban sendmail' 'fail2ban sendmail')
sendmail_packs=('false' 'sendmail-bin sendmail' 'epel-release sendmail' 'sendmail' 'sendmail' 'sendmail' 'sendmail')

_get_os_index(){
    if chkcmd apt-get; then
        # Debian
        echo 1
    elif chkcmd yum; then
        # Centos
        echo 2
    elif chkcmd dnf; then
        # Fedora
        echo 3
    elif chkcmd pacman; then
        # Archlinux
        echo 4
    elif chkcmd emaint; then
        # Gentoo
        echo 5
    elif chkcmd slackpkg; then
        # Slackware
        echo 6
    else
        echo 0
    fi
}

################################################################################
# System utils
################################################################################

system_update(){
    # * update the system
    # * some os may perform total upgrade like archlinux, centos, fedora
    ${update_command[$(_get_os_index)]}
}

system_upgrade(){
    # * upgrade the system
    system_update
    ${upgrade_command[$(_get_os_index)]}
}

system_get_install_command(){
    # * get package manager install command
    echo "${install_command[$(_get_os_index)]}"
}

system_get_primary_ip() {
    # * returns the primary IP assigned to a network interface
    # * `$1` - Required - network interface, default: eth0
    echo "$(ifconfig "${1:-eth0}" | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')"
}

system_get_rdns(){
    # * calls host on an IP address and returns its reverse dns
    # * `$1` - Required - ip address
    if ! chkcmd host; then
        $(system_get_install_command) dnsutils > /dev/null 2>&1
    fi
    echo "$(host "$1" | awk '/pointer/ {print $5}' | sed 's/\.$//')"
}

system_get_rdns_primary_ip() {
    # * returns the reverse dns of the primary IP assigned to this system
    # * `$1` - Required - Network interface, default: eth0
    echo "$(system_get_rdns "$(system_primary_ip "$1")")"
}

system_set_hostname() {
    # * `$1` - Required - The hostname to define
    HOSTNAME="$1"
        
    if [ ! -n "$HOSTNAME" ]; then
        err_out "Hostname undefined"
        return 1;
    fi
    
    if chkcmd hostnamectl; then
        # Arch / CentOS 7 / Debian 8 / Fedora version 18 and above / Ubuntu 15.04 and above
        hostnamectl set-hostname "$HOSTNAME"
    elif chkcmd apt-get || chkcmd slackpkg; then
        # Debian 7 / Slackware / Ubuntu 14.04
        echo "$HOSTNAME" > /etc/hostname
        hostname -F /etc/hostname
        if [ -f "/etc/default/dhcpcd" ]; then
            sed -i'.bak' 's/SET_HOSTNAME[[:blank:]]*=/#&/g' /etc/default/dhcpcd
        fi
    elif chkcmd yum || chkcmd dnf; then
        # CentOS 6 / Fedora version 17 and below
        echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
        hostname "$HOSTNAME"
    elif chkcmd emaint; then
        # Gentoo
        echo "HOSTNAME=\"$HOSTNAME\"" > /etc/conf.d/hostname
        /etc/init.d/hostname restart
    else
        return 1
    fi
}

system_add_host_entry(){
    # * `$1` - Required - The IP address to set a hosts entry for
    # * `$2` - Required - The FQDN to set to the IP
    IPADDR="$1"
    FQDN="$2"

    if [ -z "$IPADDR" ] || [ -z "$FQDN" ]; then
        err_out "IP address and/or FQDN Undefined"
        return 1;
    fi
    
    echo "$IPADDR" "$FQDN"  >> /etc/hosts
}


################################################################################
# Users and Authentication
################################################################################


user_add_with_sudo(){
    # * Installs sudo if needed and creates a user in the sudo group.
    #
    # * `$1` - Required - username
    # * `$2` - Required - password
    # * `$3` - Optional - shell
    USERNAME="$1"
    USERPASS="$2"
    USERSHELL="$3"

    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPASS" ]; then
        err_out "No new username and/or password entered"
        return 1;
    fi
    
    if [[ "$USERSHELL" != '' ]]; then
        usermod_opts=(-s "$USERSHELL")
        $(system_get_install_command) "$USERSHELL"
    fi
    
    $(system_get_install_command) sudo
    $(system_get_install_command) adduser
    
    #adduser "$USERNAME" --disabled-password --gecos ""
    useradd -m "$USERNAME" "${usermod_opts[@]}" &&
    msg_out "Added user $USERNAME" ||
    err_out "Failed to add user $USERNAME"
    
    echo "$USERNAME:$USERPASS" | chpasswd &&
    msg_out "Updated password for $USERNAME" ||
    err_out "Failed to update password for $USERNAME"
    
    sudoers=/etc/sudoers
    if [[ "${oss[$(_get_os_index)]}" = Centos ]] || [[ "${oss[$(_get_os_index)]}" = Fedora ]]; then
        groupadd wheel
        
        usermod -aG wheel "$USERNAME" &&
        msg_out "Added $USERNAME to group 'wheel'" ||
        err_out "Failed to add $USERNAME to group 'wheel'"
        
        sed -i'.bak' -e 's/^[[:blank:]]*#*[[:blank:]]*\(%wheel[[:blank:]][[:blank:]]*ALL=(ALL).*\)/\1/' "$sudoers" &&
        msg_out "Enabled group wheel in $sudoers" ||
        err_out "Failed to enable group wheel in $sudoers"
    else
        groupadd sudo
        
        usermod -aG sudo "$USERNAME" &&
        msg_out "Added $USERNAME to group 'sudo'" ||
        err_out "Failed to add $USERNAME to group 'sudo'"
        
        sed -i'.bak' -e 's/^[[:blank:]]*#*[[:blank:]]*\(%sudo[[:blank:]][[:blank:]]*ALL=(ALL).*\)/\1/' "$sudoers" &&
        msg_out "Enabled group sudo in $sudoers" ||
        err_out "Failed to enable group sudo in $sudoers"
    fi
}


################################################################################
# Security
################################################################################

###########
### SSH ###
###########

ssh_start(){
    # * start ssh service
    systemctl start sshd ||
    service ssh start
}

ssh_restart(){
    # * restart ssh service
    systemctl restart sshd ||
    service ssh restart
}

ssh_user_add_pubkey(){
    # * Adds the users public key to authorized_keys for the specified user.
    # * Make sure you wrap your input variables in double quotes, or the key may not load properly.
    #
    #
    # * `$1` - Required - username
    # * `$2` - Required - public key
    USERNAME="$1"
    USERPUBKEY="$2"
    
    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPUBKEY" ]; then
        err_out "Must provide a username and the location of a pubkey"
        return 1;
    fi
    
    if [ "$USERNAME" == "root" ]; then
        mkdir /root/.ssh
        if echo "$USERPUBKEY" >> /root/.ssh/authorized_keys; then
            msg_out "Added pubkey to /root/.ssh/authorized_keys"
            return 0
        else
            err_out "Failed to add pubkey to /root/.ssh/authorized_keys"
            return 1
        fi
    fi
    
    mkdir -p /home/$USERNAME/.ssh
    if echo "$USERPUBKEY" >> /home/$USERNAME/.ssh/authorized_keys; then
        chown -R "$USERNAME":"$USERNAME" /home/$USERNAME/.ssh
        msg_out "Added pubkey to /home/$USERNAME/.ssh/authorized_keys"
        return 0
    else
        err_out "Failed to add pubkey to /home/$USERNAME/.ssh/authorized_keys"
        return 1
    fi
}

ssh_disable_root_login(){
    # * Disables root SSH access.
    if sed -i'.bak' 's/PermitRootLogin[[:blank:]][[:blank:]]*yes/PermitRootLogin no/' /etc/ssh/sshd_config; then
        msg_out "Disabled root login in SSH"
        return 0
    else
        err_out "Failed to disable root login in SSH"
        return 1
    fi
}

ssh_restrict_address_family(){
    # * `$1` - Required - Address family, inet for IPV4 and inet6 of IPV6
    if echo "AddressFamily $1" | sudo tee -a /etc/ssh/sshd_config; then
        msg_out "Added 'AddressFamily $1' to /etc/ssh/sshd_config"
        return 0
    else
        err_out "Failed to add AddressFamily $1' to /etc/ssh/sshd_config"
        return 1
    fi
}

################
### Fail2Ban ###
################

fail2ban_start(){
    # * start and enable fail2ban
    systemctl start fail2ban || service fail2ban start
    systemctl enable fail2ban
}

fail2ban_restart(){
    # * restart fail2ban
    systemctl restart fail2ban || service fail2ban restart
}

fail2ban_install(){
    # * install **fail2ban**
    $(system_get_install_command) ${fail2ban_packs[$(_get_os_index)]}
    mkdir -p /var/run/fail2ban
    fail2ban_start
}

###########
### UFW ###
###########

ufw_restart(){
    # * restart ufw
    systemctl restart ufw || service ufw restart
    systemctl enable ufw
}

ufw_start(){
    # * start and enable ufw
    systemctl start ufw || service ufw start
    systemctl enable ufw
}

ufw_allow_commons(){
    # * allow common service ports
    ufw allow ssh   # SSH, 22
    ufw allow ftp   # FTP, 21/tcp
    ufw allow http  # HTTP, 80
    ufw allow https # HTTPS, 443
    ufw allow 25    # incoming SMTP
    ufw allow 143   # incoming IMAP
    ufw allow 993   # incoming IMAPS
    ufw allow 110   # incoming POP3
    ufw allow 995   # incoming POP3S
}

ufw_install(){
    # * install **ufw** (debian, ubuntu, and archlinux)
    system_update
    $(system_get_install_command) ufw
    if chkcmd ufw; then
        ufw_allow_commons
        ufw default deny incoming
        ufw default allow outgoing
        ufw_start
    else
        return 1
    fi
}

################################################################################
# Install softwares
################################################################################

##############
### common ###
##############

common_install(){
    # * Install some common packages: git, wget, bc, tar, gzip, lzip inxi
    packs=(git wget bc tar gzip lzip inxi)
    for pack in "${packs[@]}"; do
        if $(system_get_install_command) $pack; then
            msg_out "Successfully installed '$pack'"
        else
            err_out "Failed to install '$pack'"
        fi
    done
}

colorful_bash_prompt_install(){
    # * Install a colorful bash prompt
    if ! chkcmd wget; then
        $(system_get_install_command) wget
    fi
    wget -O .bashrc https://raw.githubusercontent.com/neurobin/DemoCode/master/bash/.bashrc
    mv -f $HOME/.bashrc $HOME/.bashrc.bkp
    cp .bashrc $HOME/.bashrc
    mv -f /etc/skel/.bashrc /etc/skel/.bashrc.bkp
    cp .bashrc /etc/skel/.bashrc
    mv -f /etc/bash.bashrc /etc/bash.bashrc.bkp
    cp .bashrc /etc/bash.bashrc
}


################
### sendmail ###
################

sendmail_start(){
    # * Start sendmail service
    systemctl start sendmail || service sendmail start
    systemctl enable sendmail
}

sendmail_restart(){
    # * Restart sendmail service
    systemctl restart sendmail || service sendmail restart
}

sendmail_install(){
    # * Install and start **sendmail** service
    $(system_get_install_command) ${sendmail_packs[$(_get_os_index)]}
    if chkcmd sendmail; then
        sendmail_start
        echo "include(\`/etc/mail/tls/starttls.m4')dnl" | tee -a /etc/mail/sendmail.mc /etc/mail/submit.mc
        yes | sendmailconfig
        sendmail_restart
    else
        return 1
    fi
}


###############
### Apache2 ###
###############


apache2_start(){
    # * start apache2
    systemctl start apache2 ||
    service apache2 start
}

apache2_restart(){
    # * restart apache2
    systemctl restart apache2 ||
    service apache2 restart
}

apache2_install() {
    # * installs the system default **apache2**
    $(system_get_install_command) apache2
    if chkcmd a2dissite; then
        a2dissite default # disable the interfering default virtualhost

        # clean up, or add the NameVirtualHost line to ports.conf
        sed -i -e 's/^NameVirtualHost \*$/NameVirtualHost *:80/' /etc/apache2/ports.conf
        if ! grep -q NameVirtualHost /etc/apache2/ports.conf; then
            echo 'NameVirtualHost *:80' > /etc/apache2/ports.conf.tmp
            cat /etc/apache2/ports.conf >> /etc/apache2/ports.conf.tmp
            mv -f /etc/apache2/ports.conf.tmp /etc/apache2/ports.conf
        fi
    else
        return 1
    fi
}

apache2_tune(){
    # * Tunes Apache's memory to use the percentage of RAM you specify, defaulting to 40%

    # * `$1` - the percent of system memory to allocate towards Apache

    PERCENT=${1:-40}

    $(system_get_install_command) apache2-mpm-prefork
    
    PERPROCMEM=10 # the amount of memory in MB each apache process is likely to utilize
    MEM=$(grep MemTotal /proc/meminfo | awk '{ print int($2/1024) }') # how much memory in MB this system has
    MAXCLIENTS=$((MEM*PERCENT/100/PERPROCMEM)) # calculate MaxClients
    MAXCLIENTS=${MAXCLIENTS/.*} # cast to an integer
    sed -i.bak -e "s/\(^[ \t]*MaxClients[ \t]*\)[0-9]*/\1$MAXCLIENTS/" /etc/apache2/apache2.conf
}

apache2_tune_with_defaults(){
    # * Tune apache2 according to linode ram size
    msg_out "Tuning apache2 for LINODE_RAM=$LINODE_RAM"
    content="
    <IfModule mpm_prefork_module>
        StartServers $((2*(LINODE_RAM/1024)))
        MinSpareServers $((10*(LINODE_RAM/1024)))
        MaxSpareServers $((20*(LINODE_RAM/1024)))
        MaxClients $((100*(LINODE_RAM/1024)))
        MaxRequestsPerChild $((2250*(LINODE_RAM/1024)))
    </IfModule>
    "
    if echo "$content" | tee -a /etc/apache2/apache2.conf; then
        msg_out "Apache2 tuning successfull"
        return 0
    else
        err_out 'Apache2 tuning failed!!!'
        return 1
    fi
}


###########################################################
# mysql
###########################################################

mysql_start(){
    # * start mysql service
    systemctl start mysql ||
    service mysql start
}

mysql_restart(){
    # * restart mysql service
    systemctl restart mysql ||
    service mysql restart
}

mysql_install(){
    # * Install **mysql** (Debian/Ubuntu)
    # * `$1` - the mysql root password
    
    if [[ "${oss[$(_get_os_index)]}" != Debian ]]; then
        err_out "mysql_install() function is not compatible with non-debian like systems"
        return 1
    fi
    
    if [ ! -n "$1" ]; then
        echo "mysql_install() requires the root pass as its first argument"
        return 1;
    fi

    echo "mysql-server mysql-server/root_password password $1" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $1" | debconf-set-selections
    $(system_get_install_command) mysql-server mysql-client
    msg_out "Sleeping while MySQL starts up for the first time..."
    sleep 3
}

mysql_security_tune(){
    # * Secure MySQL with `mysql_secure_installation`
    # * `$1` - the mysql root password
    if ! chkcmd expect; then
        $(system_get_install_command) expect
    fi
    msg_out "Securing mysql with mysql_secure_installation"
    
    tmpf=$(mktemp)
    echo "#!/usr/bin/expect -f
    set timeout -1
    spawn mysql_secure_installation --use-default
    match_max 100000
    expect -nocase \"*assword for user root:*\"
    exp_send -- \"$1\r\"
    exp_send -- \"\x04\"
    exp_send -- \"\x04\"
    exp_send -- \"\x04\"
    expect eof
    " > "$tmpf"
    msg_out "Executing expect script: $tmpf\n"
    expect "$tmpf"
    rm -f "$tmpf" &&
    msg_out "Removed expect script: $tmpf" ||
    wrn_out "Failed to remove expect script: $tmpf"
}

_insert_prop(){
    prop=$1
    val=$2
    file=$3
    section_re=$4
    section_raw=$5
    if grep -qs -e "^[[:blank:]]*$prop[[:blank:]]*=[[:blank:]]*" "$file"; then
        if sed -i.bak "s/\(^[[:blank:]]*$prop[[:blank:]]*=[[:blank:]]*\).*/\1$val/" "$file"; then
            msg_out "Successfully inserted '$prop = $val' in $file"
            return 0
        else
            err_out "Failed to insert '$prop = $val' in $file"
            return 1
        fi
    elif grep -qs -e "^[[:blank:]]*$section_re[[:blank:]]*"; then
        if sed -i.bak "s/^[[:blank:]]*$section_re[[:blank:]]*.*/&\n$prop = $val/" "$file"; then
            msg_out "Successfully inserted '$prop = $val' in $file"
            return 0
        else
            err_out "Failed to insert '$prop = $val' in $file"
            return 1
        fi
    else
        if cat >> "$file" <<< "$section_raw
$prop = $val"; then
            msg_out "Successfully inserted '$prop = $val' in $file"
            return 0
        else
            err_out "Failed to insert '$prop = $val' in $file"
            return 1
        fi
    fi
}

mysql_tune(){
    # * Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%

    # * `$1` - the percent of system memory to allocate towards MySQL

    PERCENT=${1:-40}

    sed -i.bak -e 's/^#skip-innodb/skip-innodb/' /etc/mysql/my.cnf # disable innodb - saves about 100M

    MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) # how much memory in MB this system has
    MYMEM=$((MEM*PERCENT/100)) # how much memory we'd like to tune mysql with
    MYMEMCHUNKS=$((MYMEM/4)) # how many 4MB chunks we have to play with

    # mysql config options we want to set to the percentages in the second list, respectively
    OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size myisam_sort_buffer_size query_cache_size)
    DISTLIST=(75 1 1 1 5 15)

    for opt in "${OPTLIST[@]}"; do
        sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/mysql/my.cnf
    done

    for i in ${!OPTLIST[*]}; do
        val=$(echo | awk "{print int((${DISTLIST[$i]} * $MYMEMCHUNKS/100))*4}")
        if [ $val -lt 4 ]
            then val=4
        fi
        config="${config}\n${OPTLIST[$i]} = ${val}M"
    done

    sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/mysql/my.cnf
}

mysql_tune_with_defaults(){
    # * Tune mysql according to linode RAM size
    mysql_tune
    sed -i -e 's/^[[:blank:]]*key_buffer.*/#&/' /etc/mysql/my.cnf
    max_allowed_packet=$((512*(LINODE_RAM/1024)))K
    thread_stack=$((64*(LINODE_RAM/1024)))K
    max_connections=$((37*(LINODE_RAM/1024)))
    _insert_prop max_allowed_packet $max_allowed_packet /etc/mysql/my.cnf '\[mysqld\]' '[mysqld]'
    _insert_prop thread_stack $thread_stack /etc/mysql/my.cnf '\[mysqld\]' '[mysqld]'
    _insert_prop max_connections $max_connections /etc/mysql/my.cnf '\[mysqld\]' '[mysqld]'
    
    table_open_cache=$((16*(LINODE_RAM/1024)))M
    key_buffer_size=$((16*(LINODE_RAM/1024)))M
    cont="
table_open_cache = $table_open_cache
key_buffer_size = $key_buffer_size
"
    if echo "$cont" | tee -a /etc/mysql/my.cnf; then
        msg_out "Added $cont to /etc/mysql/my.cnf"
        return 0
    else
        err_out "Failed to add $cont to /etc/mysql/my.cnf"
        return 1
    fi
}
