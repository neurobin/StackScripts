#!/bin/bash
# ##############################################################################
# ############################### funcs.sh #####################################
# ##############################################################################
#            Copyright (c) 2015-2017 Md. Jahidul Hamid
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
    # $1: command
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}


################################################################################
# System utils
################################################################################

system_update(){
    # System upgrade
    if chkcmd apt; then
        apt update
        apt upgrade
    elif chkcmd apt-get; then
        apt-get update
        apt-get upgrade
    elif chkcmd yum; then
        yum update
    elif chkcmd dnf; then
        dnf upgrade
    elif chkcmd pacman; then
        pacman -Syu
    elif chkcmd emaint; then
        emaint sync
        emerge --uDN @world
    elif chkcmd slackpkg; then
        slackpkg update
        slackpkg upgrade-all
    fi
}

system_primary_ip() {
    # returns the primary IP assigned to a network interface
    # $1: network interface, default: eth0
    echo "$(ifconfig "${1:-eth0}" | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')"
}

get_rdns(){
    # calls host on an IP address and returns its reverse dns
    # $1: ip address
    if ! chkcmd host; then
        apt-get install -y dnsutils > /dev/null 2>&1
    fi
    echo "$(host "$1" | awk '/pointer/ {print $5}' | sed 's/\.$//')"
}

get_rdns_primary_ip() {
    # returns the reverse dns of the primary IP assigned to this system
    # $1: network interface, default: eth0
    echo "$(get_rdns "$(system_primary_ip "$1")")"
}


system_set_hostname() {
    # $1 - The hostname to define
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

function system_add_host_entry {
    # $1 - The IP address to set a hosts entry for
    # $2 - The FQDN to set to the IP
    IPADDR="$1"
    FQDN="$2"

    if [ -z "$IPADDR" -o -z "$FQDN" ]; then
        err_out "IP address and/or FQDN Undefined"
        return 1;
    fi
    
    echo "$IPADDR" "$FQDN"  >> /etc/hosts
}
