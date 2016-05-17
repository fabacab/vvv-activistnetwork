#
# @file vvv-init.sh
#
# Provision WordPress Multisite stable as a base for the Activist Network Platform
# and automatically pre-configure the ANP-specific packages across the network.
#

# Globals.
VVV_ANP_CONFIG_DIR=`pwd`
VVV_ANP_NETWORK_DOMAINS=(
    `grep -E '^[^\.]*+\.[^\.]*+$' "$VVV_ANP_CONFIG_DIR/vvv-hosts"`
) # Array of network domain root URLs.

# Custom globals.
# These customize the behavior of the provisioner.
if [ -f "$VVV_ANP_CONFIG_DIR"/anp-config.sh ] && [ -r "$VVV_ANP_CONFIG_DIR"/anp-config.sh ]; then
    source "$VVV_ANP_CONFIG_DIR"/anp-config.sh
fi

# Function: anpGetNetworkRootDomain
#
# Gets the root domain for a given WP Multi-Network network.
#
# @param string $1 The network number, starting at 1 (for main network root)
#
# @return string The domain name of the network.
#
function anpGetNetworkRootDomain () {
    echo "${VVV_ANP_NETWORK_DOMAINS[$1]}"
}

# Function: anpGetArgsInFile
#
# Gets a single list of arguments from a file ignoring lines with `#`
#
# @param string $1 Path to a file containing arguments
#
# @return string The argument list, space separated
#
function anpGetArgsInFile () {
    echo `grep -v '#' "$1" | paste -s -d ' ' -`
}

#
# Function: anpActivatePlugins
#
# Reads plugin slugs from a file and activates the plugins listed there.
# The file must be suffixed with `-plugins.txt` to be considered.
#
# If the file is called `network-plugins.txt`, then the plugins will be
# network-activated. If the file is called `mainsite-plugins.txt`, then
# the plugins will be activated only for network's mainsite. If the file
# is named anything else then the name (excluding the `-plugins.txt part)
# will be treated as the WP site URL for which to activate the plugins.
#
# @param string $1 Path to a file containing plugin slugs to activate.
#
function anpActivatePlugins () {
    local file="$1"
    local args=`anpGetWordPressContext "$file"`
    wp plugin activate `anpGetArgsInFile "$file"` "$args" --allow-root
}

#
# Function: anpActivateThemes
#
# @see anpActivatePlugins
#
function anpActivateThemes () {
    local file="$1"
    local args=`anpGetWordPressContext "$file"`
    for theme in `anpGetArgsInFile "$file"`; do
        wp theme activate "$theme" "$args" --allow-root
    done
}

#
# Function: anpEnableThemes
#
# @see anpActivatePlugins
#
function anpEnableThemes () {
    local file="$1"
    local args=`anpGetWordPressContext "$file"`
    for theme in `anpGetArgsInFile "$file"`; do
        wp theme enable "$theme" "$args" --allow-root
    done
}

#
# Function: anpGetWordPressContext
#
# Parses a filename for the appropriate WordPress context in which to
# apply it and returns the correct argument for a WP-CLI command.
#
# Filenames are expected to end in `-plugins.txt` or `-themes.txt`.
# These suffixes are stripped and the remainder is inspected to find
# an appropriate context, which can be one of `network`, `mainsite`,
# or a literal Fully-Qualified Domain Name like `site2.example.dev`.
#
# @global $VVV_ANP_NETWORK_DOMAINS
#
# @param string $1 Path to a file.
# @param string $2 Numeric network ID. Defaults to `1`.
#
# @return string Command-line argument(s) ready to pass to a `wp` command.
#
function anpGetWordPressContext () {
    local file=`basename "$1"`
    local site
    site="${file%-plugins.txt}" # strip -plugins.txt
    site="${site%-themes.txt}"  # strip -themes.txt

    if [ "$site" == "network" ]; then
        site="--network"
    elif [ "$site" == "mainsite" ]; then
        site="--url=${VVV_ANP_NETWORK_DOMAINS[${2:-1}]}" # default to network number 1
    else
        site="--url=$site"
    fi

    echo "$site" # "Return" the argument string.
}

#
# MAIN
#
# TODO: Make this an actual function, eh?
#

# Make a database, if we don't already have one
echo -e "\nCreating database 'wordpress_anp' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS wordpress_anp"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON wordpress_anp.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
if [[ ! -d /srv/log/wordpress-anp ]]; then
    mkdir /srv/log/wordpress-anp
fi
touch /srv/log/wordpress-anp/error.log
touch /srv/log/wordpress-anp/access.log

# Install and configure the latest stable version of WordPress
if [[ ! -d /srv/www/wordpress-anp ]]; then

    mkdir /srv/www/wordpress-anp
    cd /srv/www/wordpress-anp

    echo "Downloading WordPress Multisite (Subdomain Stable) for Activist Network Platform, see https://glocal.coop/activist-network-platform/"
    wp core download --allow-root

    echo "Configuring WordPress Multisite Subdomain Stable..."
    wp core config --dbname=wordpress_anp --dbuser=wp --dbpass=wp --extra-php --allow-root <<PHP
// Match any requests made via xip.io or for WP Multi-Network.
if ( isset( \$_SERVER['HTTP_HOST'] ) ) {
    define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
    define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
}

// Shared cookies across multi-domain WP multi-Network setup
define( 'COOKIEHASH',        md5( '${VVV_ANP_NETWORK_DOMAINS[0]}' ) );
define( 'COOKIE_DOMAIN',     '${VVV_ANP_NETWORK_DOMAINS[0]}'        );
define( 'ADMIN_COOKIE_PATH', '/' );
define( 'COOKIEPATH',        '/' );
define( 'SITECOOKIEPATH',    '/' );
define( 'TEST_COOKIE',        'wpmn_test_cookie' );
define( 'AUTH_COOKIE',        'wpmn_'          . COOKIEHASH );
define( 'USER_COOKIE',        'wpmn_user_'     . COOKIEHASH );
define( 'PASS_COOKIE',        'wpmn_pass_'     . COOKIEHASH );
define( 'SECURE_AUTH_COOKIE', 'wpmn_sec_'      . COOKIEHASH );
define( 'LOGGED_IN_COOKIE',   'wpmn_logged_in' . COOKIEHASH );

define( 'WP_DEBUG'    , true );
define( 'WP_DEBUG_LOG', true );
PHP
    echo "Installing WordPress Multisite (Subdomain Stable) for Activist Network Platform..."
    wp core multisite-install --allow-root --url="${VVV_ANP_NETWORK_DOMAINS[0]}" --subdomains --title="Activist Network Platform (Subdomain) localDev" --admin_name=admin --admin_email="anp.admin@local.dev" --admin_password="password"

    # Create site admin
    wp user create --allow-root "siteadmin" "admin@local.dev" --user_pass="password"

    # Create sites 2-5
    for i in {2..5}; do
        wp site create --allow-root --slug="site$i" --title="ANP Subsite ($i)" --email="admin@local.dev"
    done

    echo "Installing Activist Network Platform pre-configuration using Composer..."
    git clone ${VVV_ANP_COMPOSER_GIT:-https://github.com/glocalcoop/activist-network-composer.git} anp-composer
    mv anp-composer/composer.{json,lock} ./
    rm -rf anp-composer
    composer ${VVV_ANP_COMPOSER_CMD:-install}

    wp plugin update --all --allow-root
    wp theme update --all --allow-root

    # Configure ANP-specific defaults.
    # TODO: Replace this custom PHP and shell stuff with Variable VV's PHP install helper?
    php "$VVV_ANP_CONFIG_DIR"/vvv-init.php
    for file in `ls "$VVV_ANP_CONFIG_DIR"/*-plugins.txt`; do
        anpActivatePlugins "$file"
    done
    for file in `ls "$VVV_ANP_CONFIG_DIR"/*-themes.txt`; do
        anpEnableThemes "$file"
    done
    rm -f "$VVV_ANP_CONFIG_DIR"/*-{plugins,themes}.txt
    for url in `wp site list --field=url --allow-root`; do
        wp theme activate anp-network-main-child --url="$url" --quiet --allow-root
    done
    wp theme activate anp-network-main --url="${VVV_ANP_NETWORK_DOMAINS[0]}" --allow-root

    # Create subsite users
    wp user create subscriber1 "subscriber1@local.dev" --role=subscriber --user_pass=password --url=site2."${VVV_ANP_NETWORK_DOMAINS[0]}" --allow-root
    wp user create subscriber2 "subscriber2@local.dev" --role=subscriber --user_pass=password --url=site2."${VVV_ANP_NETWORK_DOMAINS[0]}" --allow-root

    # Replace static configuration with WP Multi-Network constant.
    # From here on out, most `wp` commands require the `--url` argument.
    sed "s/DOMAIN_CURRENT_SITE\(.*\)'${VVV_ANP_NETWORK_DOMAINS[0]}'/DOMAIN_CURRENT_SITE\1\$_SERVER['HTTP_HOST']/" wp-config.php > tmpconfig.php
    mv tmpconfig.php wp-config.php

    # Create sub-network domain(s).
    for domain in "${VVV_ANP_NETWORK_DOMAINS[@]}"; do
        wp wp-multi-network create "$domain" "/" --user=admin --allow-root --url="${VVV_ANP_NETWORK_DOMAINS[0]}"
        # Create sites 2-5
        for i in {7..10}; do
            wp site create --allow-root --slug="site$i" --title="ANP $domain Subsite ($i)" --email="admin@local.dev" --url="$domain"
        done
    done

else

    echo "Updating WordPress Multisite (Subdomain Stable) for Activist Network Platform..."
    cd /srv/www/wordpress-anp
    wp core upgrade --allow-root

fi
