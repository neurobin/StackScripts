#!/bin/bash
# <UDF name="update_mode" Label="Update mode" oneOf="update,upgrade" default="upgrade" />
# <UDF name="system_hostname" Label="System hostname" example="myhostname" />
# <UDF name="user_name" Label="Standard username" example="user" />
# <UDF name="user_password" Label="Password for standard user" />
# <UDF name="user_shell" Label="Default SHELL for standard user" default="/bin/bash" example="/full/path/to/shell" />
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

mkdir -p /var/cache
exec &>  >(tee -a /var/cache/initserver.sh.log)

source <ssinclude StackScriptID="182722">

if [[ "$UPDATE_MODE" = update ]]; then
    system_update
elif [[ "$UPDATE_MODE" = upgrade ]]; then
    system_upgrade
fi

if [[ -n "$SYSTEM_HOSTNAME" ]]; then
    system_set_hostname "$SYSTEM_HOSTNAME"
    system_add_host_entry 127.0.1.1 "$SYSTEM_HOSTNAME"
fi

if [[ "$COLORFUL_BASH_PROMPT_INSTALL" = yes ]]; then
    colorful_bash_prompt_install
fi

if [[ -n "$USER_NAME" ]] && [[ -n "$USER_PASSWORD" ]]; then
    user_add_with_sudo "$USER_NAME" "$USER_PASSWORD" $USER_SHELL
fi

if [[ -n "$SSH_USER" ]] && [[ -n "$SSH_PUBKEY" ]]; then
    ssh_user_add_pubkey "$SSH_USER" "$SSH_PUBKEY"
fi

if [[ "$SSH_DISABLE_ROOT_LOGIN" = yes ]]; then
    ssh_disable_root_login
fi

if [[ -n "$SSH_RESTRICT_ADDRESS_FAMILY" ]]; then
    ssh_restrict_address_family "$SSH_RESTRICT_ADDRESS_FAMILY"
    ssh_restart
fi

if [[ "$COMMON_INSTALL" = yes ]]; then
    common_install
fi

if [[ "$FAIL2BAN_INSTALL" = yes ]]; then
    fail2ban_install
fi

if [[ "$UFW_INSTALL" = yes ]]; then
    ufw_install
fi

if [[ "$SENDMAIL_INSTALL" = yes ]]; then
    sendmail_install
fi

if [[ "$APACHE2_INSTALL" = yes ]]; then
    apache2_install
    apache2_tune_with_defaults
    apache2_restart
fi

if [[ "$MYSQL_INSTALL" = yes ]]; then
    mysql_install "$MYSQL_ROOT_PASSWORD"
    mysql_tune_security "$MYSQL_ROOT_PASSWORD"
    mysql_tune_with_defaults
    mysql_restart
fi
