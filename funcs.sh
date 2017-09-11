#!/bin/bash
# ##############################################################################
# ############################### funcs.sh #####################################
# ##############################################################################
#
# Copyright (c) 2010 Linode LLC / Christopher S. Aker <caker@linode.com>
# All rights reserved.
#
# Copyright (c) 2015-2017 Md. Jahidul Hamid. All rights reserved.
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


################################################################################
# Message printing functions
################################################################################

msg_out(){
	printf '\n%b\n' "*** $*"
}

err_out(){
	printf '\n%b\n' "E: $*" >&2
}

wrn_out(){
	printf '\n%b\n' "W: $*" >&2
}

err_exit(){
	err_out "$*"
	exit 1
}


################################################################################
# Checks
################################################################################

chkcmd(){
    # Check if a command is available
    # $1 - Required - command
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Compatibility layer
################################################################################

oss=(Unknown Debian-apt Debian-apt-get Centos Fedora Archlinux Gentoo Slackware)
install_command=('false' 'apt install -y' 'apt-get install -y' 'yum install -y' 'dnf -y install' 'pacman -S' 'emerge' 'slackpkg install')
update_command=('false' 'apt update; apt upgrade' 'apt-get update; apt-get upgrade' 'yum update' 'dnf upgrade' 'pacman -Syu' 'emaint sync; emerge --uDN @world' 'slackpkg update; slackpkg upgrade-all')
fail2ban_packs=('false' 'fail2ban sendmail-bin sendmail' 'fail2ban sendmail-bin sendmail' 'epel-release fail2ban sendmail' 'fail2ban sendmail' 'fail2ban sendmail' 'fail2ban sendmail' 'fail2ban sendmail')

get_os_index(){
    # System upgrade
    if chkcmd apt; then
        # Debian-apt
        echo 1
    elif chkcmd apt-get; then
        # Debian-apt-get
        echo 2
    elif chkcmd yum; then
        # Centos
        echo 3
    elif chkcmd dnf; then
        # Fedora
        echo 4
    elif chkcmd pacman; then
        # Archlinux
        echo 5
    elif chkcmd emaint; then
        # Gentoo
        echo 6
    elif chkcmd slackpkg; then
        # Slackware
        echo 7
    else
        echo 0
    fi
}

################################################################################
# System utils
################################################################################

system_update(){
    ${update_command[$(get_os_index)]}
}

system_get_install_command(){
    echo "${install_command[$(get_os_index)]}"
}

system_primary_ip() {
    # returns the primary IP assigned to a network interface
    # $1 - Required - network interface, default: eth0
    echo "$(ifconfig "${1:-eth0}" | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')"
}

get_rdns(){
    # calls host on an IP address and returns its reverse dns
    # $1 - Required - ip address
    if ! chkcmd host; then
        $(system_get_install_command) dnsutils > /dev/null 2>&1
    fi
    echo "$(host "$1" | awk '/pointer/ {print $5}' | sed 's/\.$//')"
}

get_rdns_primary_ip() {
    # returns the reverse dns of the primary IP assigned to this system
    # $1 - Required - Network interface, default: eth0
    echo "$(get_rdns "$(system_primary_ip "$1")")"
}


system_set_hostname() {
    # $1 - Required - The hostname to define
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
    fi
    
}

system_add_host_entry(){
    # $1 - Required - The IP address to set a hosts entry for
    # $2 - Required - The FQDN to set to the IP
    IPADDR="$1"
    FQDN="$2"

    if [ -z "$IPADDR" -o -z "$FQDN" ]; then
        err_out "IP address and/or FQDN Undefined"
        return 1;
    fi
    
    echo "$IPADDR" "$FQDN"  >> /etc/hosts
}

################################################################################
# Security
################################################################################

###########
### SSH ###
###########

ssh_restart(){
    systemctl restart sshd ||
    service ssh restart
}

ssh_user_add_pubkey(){
    # Adds the users public key to authorized_keys for the specified user.
    # Make sure you wrap your input variables in double quotes, or the key may not load properly.
    #
    #
    # $1 - Required - username
    # $2 - Required - public key
    USERNAME="$1"
    USERPUBKEY="$2"
    
    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPUBKEY" ]; then
        err_out "Must provide a username and the location of a pubkey"
        return 1;
    fi
    
    if [ "$USERNAME" == "root" ]; then
        mkdir /root/.ssh
        echo "$USERPUBKEY" >> /root/.ssh/authorized_keys
        return 0
    fi
    
    mkdir -p /home/$USERNAME/.ssh
    echo "$USERPUBKEY" >> /home/$USERNAME/.ssh/authorized_keys
    chown -R "$USERNAME":"$USERNAME" /home/$USERNAME/.ssh
}

# compatibility with linode bash lib
user_add_pubkey(){
    ssh_user_add_pubkey ${1:+"$@"}
}

ssh_disable_root(){
    # Disables root SSH access.
    sed -i'.bak' 's/PermitRootLogin[[:blank:]][[:blank:]]*yes/PermitRootLogin no/' /etc/ssh/sshd_config
    touch /tmp/restart-ssh
}

ssh_restrict_address_family(){
    # $1 - Required - Address family, inet for IPV4 and inet6 of IPV6
    echo "AddressFamily $1" | sudo tee -a /etc/ssh/sshd_config
}

################################################################################
# Users and Authentication
################################################################################


user_add_sudo(){
    # Installs sudo if needed and creates a user in the sudo group.
    #
    # $1 - Required - username
    # $2 - Required - password
    # $3 - Optional - shell
    USERNAME="$1"
    USERPASS="$2"
    USERSHELL="$3"

    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPASS" ]; then
        err_out "No new username and/or password entered"
        return 1;
    fi
    
    if [[ "$USERSHELL" != '' ]]; then
        usermod_opts="-s '$USERSHELL'"
    fi
    
    $(system_get_install_command) sudo
    $(system_get_install_command) adduser
    #adduser "$USERNAME" --disabled-password --gecos ""
    useradd -m "$USERNAME" $usermod_opts
    echo "$USERNAME:$USERPASS" | chpasswd
    sudoers=/etc/sudoers
    if [[ "${oss[$(get_os_index)]}" = Centos ]] || [[ "${oss[$(get_os_index)]}" = Fedora ]]; then
        groupadd wheel
        usermod -aG wheel "$USERNAME"
        sed -i'.bak' -e 's/^[[:blank:]]*#*[[:blank:]]*\(%wheel[[:blank:]][[:blank:]]*ALL=(ALL).*\)/\1/' "$sudoers" &&
        msg_out "Enabled group wheel in $sudoers" ||
        err_out "Failed to enable group wheel in $sudoers"
    else
        groupadd sudo
        usermod -aG sudo "$USERNAME"
        sed -i'.bak' -e 's/^[[:blank:]]*#*[[:blank:]]*\(%sudo[[:blank:]][[:blank:]]*ALL=(ALL).*\)/\1/' "$sudoers" &&
        msg_out "Enabled group sudo in $sudoers" ||
        err_out "Failed to enable group sudo in $sudoers"
    fi
}

