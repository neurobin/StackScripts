#!/bin/bash
# <UDF name="system_hostname" Label="System hostname" example="JLFUN" />
# <UDF name="user_name" Label="Standard username" example="user" />
# <UDF name="user_password" Label="Password for standard user" />
# <UDF name="ssh_user" Label="SSH user" example="user" />
# <UDF name="ssh_pubkey" Label="SSH public key" />
# <UDF name="ssh_disable_root_login" Label="Disable root login in SSH" oneOf="yes,no" default="yes" />
# <UDF name="ssh_restrict_address_family" Label="Restrict SSH AddressFamily" oneOf="inet,inet6" default="inet" />
# <UDF name="fail2ban_install" Label="Install fail2ban" oneOf="yes,no" default="yes" />
# <UDF name="ufw_install" Label="Install UFW firewall" oneOf="yes,no" default="yes" />
# <UDF name="common_install" Label="Install common packages (git, wget, tar, bc, gzip, lzip, inxi)" oneOf="yes,no" default="yes" />
# <UDF name="colorful_bash_prompt_install" Label="Install a colorful bash prompt" oneOf="yes,no" default="yes" />
# <UDF name="sendmail_install" Label="Install sendmail" oneOf="yes,no" default="yes" />
# <UDF name="apache2_install" Label="Install apache2 webserver" oneOf="yes,no" default="yes" />
# <UDF name="mysql_install" Label="Install mysql" oneOf="yes,no" default="yes" />
# <UDF name="mysql_root_password" Label="Root password for mysql" />

source <ssinclude StackScriptID="182722">

mkdir -p /var/cache
exec &> /var/cache/initserver.sh.log

system_update
system_set_hostname "$SYSTEM_HOSTNAME"
system_add_host_entry 127.0.1.1 "$SYSTEM_HOSTNAME"
user_add_with_sudo "$USER_NAME" "$USER_PASSWORD"
ssh_user_add_pubkey "$SSH_USER" "$SSH_PUBKEY"

if [[ "$SSH_DISABLE_ROOT_LOGIN" = yes ]]; then
    ssh_disable_root_login
fi

ssh_restrict_address_family "$SSH_RESTRICT_ADDRESS_FAMILY"
ssh_restart

if [[ "$FAIL2BAN_INSTALL" = yes ]]; then
    fail2ban_install
fi

if [[ "$UFW_INSTALL" = yes ]]; then
    ufw_install
fi

if [[ "$COMMON_INSTALL" = yes ]]; then
    common_install
fi

if [[ "$COLORFUL_BASH_PROMPT_INSTALL" = yes ]]; then
    colorful_bash_prompt_install
fi

if [[ "$SENDMAIL_INSTALL" = yes ]]; then
    sendmail_install
fi

if [[ "$APACHE2_INSTALL" = yes ]]; then
    apache2_install &&
    apache2_tune_with_defaults &&
    apache2_restart
fi

if [[ "$MYSQL_INSTALL" = yes ]]; then
    mysql_install "$MYSQL_ROOT_PASSWORD" &&
    mysql_tune_with_defaults &&
    mysql_restart
fi
