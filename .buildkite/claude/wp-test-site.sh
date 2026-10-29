#!/bin/bash

# Throwaway WordPress sites on this Mac, for the Claude PR review. Each site is
# a fresh self-hosted WordPress on http://localhost:<port>, which the iOS
# Simulator can reach, with an admin user and an application password.
#
# Based on `scripts/native-test-server.sh` in wordpress-rs
# (https://github.com/Automattic/wordpress-rs/pull/1665): Apache + mod_php and
# MariaDB from Homebrew, because our Mac CI VMs can't run Docker.
#
# Everything a site needs lives in $WP_TEST_SITES_DIR (default ~/.wp-test-sites).
#
# Usage: wp-test-site.sh <command>
#
#   start <name>        Create a fresh site and print its details as JSON
#   wp <name> <args>    Run WP-CLI against a site, e.g. `wp demo post list`
#   info <name>         Print a site's details as JSON
#   list                List the sites
#   stop <name>         Stop a site's web server
#   install-deps        Install PHP, MariaDB and Apache with Homebrew

set -euo pipefail

WORDPRESS_VERSION="${WORDPRESS_VERSION:-7.1.4}"
PHP_FORMULA="php@8.4"
MARIADB_FORMULA="mariadb@11.4"
WP_CLI_VERSION="2.12.0"
WP_CLI_SHA512="be928f6b8ca1e8dfb9d2f4b75a13aa4aee0896f8a9a0a1c45cd5d2c98605e6172e6d014dda2e27f88c98befc16c040cbb2bd1bfa121510ea5cdf5f6a30fe8832"

DB_PORT=3307
FIRST_SITE_PORT=8881

STATE_DIR="${WP_TEST_SITES_DIR:-$HOME/.wp-test-sites}"
SITES_DIR="$STATE_DIR/sites"
DB_DIR="$STATE_DIR/mariadb"
RUN_DIR="$STATE_DIR/run"
LOG_DIR="$STATE_DIR/logs"
WP_CLI_DIR="$STATE_DIR/wp-cli"
WP_CLI_PHAR="$WP_CLI_DIR/wp-cli-$WP_CLI_VERSION.phar"
PHP_INI="$STATE_DIR/php.ini"
DB_SOCKET="$RUN_DIR/mariadb.sock"

BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
PHP_PREFIX="$BREW_PREFIX/opt/$PHP_FORMULA"
MARIADB_PREFIX="$BREW_PREFIX/opt/$MARIADB_FORMULA"
HTTPD_PREFIX="$BREW_PREFIX/opt/httpd"

fail() {
	echo "$*" >&2
	exit 1
}

usage() {
	sed -n '/^# Usage:/,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
	exit 1
}

require_deps() {
	local missing=()

	[ -x "$PHP_PREFIX/bin/php" ] || missing+=("$PHP_FORMULA")
	[ -x "$MARIADB_PREFIX/bin/mariadbd" ] || missing+=("$MARIADB_FORMULA")
	[ -x "$HTTPD_PREFIX/bin/httpd" ] || missing+=("httpd")
	command -v jq > /dev/null || missing+=("jq")

	if [ ${#missing[@]} -gt 0 ]; then
		fail "Missing dependencies: ${missing[*]}. Install them with \`$0 install-deps\`."
	fi
}

# Runs the given command until it succeeds, giving up after 30 seconds.
wait_for() {
	local description="$1"
	shift

	local tries=0
	until "$@" > /dev/null 2>&1; do
		tries=$((tries + 1))
		if [ "$tries" -gt 30 ]; then
			echo "Timed out waiting for $description. Logs are in $LOG_DIR:" >&2
			tail -n 50 "$LOG_DIR"/*.log >&2 || true
			exit 1
		fi
		sleep 1
	done
}

port_in_use() {
	nc -z 127.0.0.1 "$1" > /dev/null 2>&1
}

# PHP's built-in defaults with the settings the official `wordpress` Docker
# image adds, rather than Homebrew's development `php.ini`.
configure_php() {
	cat > "$PHP_INI" <<-'INI'
		error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR
		display_errors = Off
		log_errors = On
		error_log = /dev/stderr
		html_errors = Off
		memory_limit = 512M
		upload_max_filesize = 64M
		post_max_size = 64M

		opcache.memory_consumption = 128
		opcache.interned_strings_buffer = 8
		opcache.max_accelerated_files = 4000
		opcache.revalidate_freq = 2
	INI
}

install_wp_cli() {
	mkdir -p "$WP_CLI_DIR"

	if [ ! -f "$WP_CLI_PHAR" ]; then
		curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v$WP_CLI_VERSION/wp-cli-$WP_CLI_VERSION.phar" -o "$WP_CLI_PHAR.tmp"
		echo "$WP_CLI_SHA512  $WP_CLI_PHAR.tmp" | shasum -a 512 -c - > /dev/null || fail "WP-CLI download didn't match its checksum."
		mv "$WP_CLI_PHAR.tmp" "$WP_CLI_PHAR"
	fi
}

# WP-CLI with the pinned PHP, without any WP-CLI configuration from this machine.
wp_cli() {
	PATH="$MARIADB_PREFIX/bin:$PATH" \
		WP_CLI_PACKAGES_DIR="$WP_CLI_DIR/packages" \
		WP_CLI_CACHE_DIR="$WP_CLI_DIR/cache" \
		WP_CLI_CONFIG_PATH="$WP_CLI_DIR/config.yml" \
		"$PHP_PREFIX/bin/php" -c "$PHP_INI" "$WP_CLI_PHAR" "$@"
}

mariadb_client() {
	"$MARIADB_PREFIX/bin/mariadb" --no-defaults --socket="$DB_SOCKET" --user=root
}

# One MariaDB server for every site, started on first use. Nothing in it needs
# to survive a crash, so it skips `fsync`, which is slow on macOS.
ensure_database() {
	if [ -S "$DB_SOCKET" ] && "$MARIADB_PREFIX/bin/mariadb-admin" --no-defaults --socket="$DB_SOCKET" --user=root ping > /dev/null 2>&1; then
		return
	fi
	port_in_use "$DB_PORT" && fail "Port $DB_PORT is in use by something else."

	rm -rf "$DB_DIR"
	"$MARIADB_PREFIX/bin/mariadb-install-db" \
		--no-defaults \
		--basedir="$MARIADB_PREFIX" \
		--datadir="$DB_DIR" \
		--auth-root-authentication-method=normal \
		--skip-test-db \
		> "$LOG_DIR/mariadb-install.log" 2>&1 || {
		cat "$LOG_DIR/mariadb-install.log" >&2
		exit 1
	}

	nohup "$MARIADB_PREFIX/bin/mariadbd" \
		--no-defaults \
		--basedir="$MARIADB_PREFIX" \
		--datadir="$DB_DIR" \
		--socket="$DB_SOCKET" \
		--pid-file="$RUN_DIR/mariadb.pid" \
		--bind-address=127.0.0.1 \
		--port="$DB_PORT" \
		--debug-no-sync \
		> "$LOG_DIR/mariadb.log" 2>&1 &

	wait_for "MariaDB" "$MARIADB_PREFIX/bin/mariadb-admin" --no-defaults --socket="$DB_SOCKET" --user=root ping
}

site_dir() {
	echo "$SITES_DIR/$1"
}

require_site() {
	[ -f "$(site_dir "$1")/site.json" ] || fail "No site called '$1'. Create it with \`$0 start $1\`."
}

next_free_port() {
	local taken
	taken="$(cat "$SITES_DIR"/*/site.json 2> /dev/null | jq -s -r 'map(.port) | join(" ")')"
	local port="$FIRST_SITE_PORT"
	while port_in_use "$port" || [[ " $taken " == *" $port "* ]]; do
		port=$((port + 1))
	done
	echo "$port"
}

start_web_server() {
	local name="$1"
	local dir
	dir="$(site_dir "$name")"
	local port
	port="$(jq -r .port "$dir/site.json")"
	local modules_dir="$HTTPD_PREFIX/lib/httpd/modules"

	# `Require local` turns away other machines. The site's PHP runs as the current user.
	cat > "$dir/httpd.conf" <<-EOF
		ServerRoot "$dir"
		ServerName localhost
		Listen 127.0.0.1:$port

		DefaultRuntimeDir "$dir"
		PidFile "$dir/httpd.pid"
		ErrorLog "$dir/httpd-error.log"
		CustomLog "$dir/httpd-access.log" "%h %t \"%r\" %>s %b %D"

		LoadModule mpm_prefork_module "$modules_dir/mod_mpm_prefork.so"
		LoadModule unixd_module "$modules_dir/mod_unixd.so"
		LoadModule authz_core_module "$modules_dir/mod_authz_core.so"
		LoadModule authz_host_module "$modules_dir/mod_authz_host.so"
		LoadModule log_config_module "$modules_dir/mod_log_config.so"
		LoadModule mime_module "$modules_dir/mod_mime.so"
		LoadModule dir_module "$modules_dir/mod_dir.so"
		LoadModule rewrite_module "$modules_dir/mod_rewrite.so"
		LoadModule setenvif_module "$modules_dir/mod_setenvif.so"
		LoadModule php_module "$PHP_PREFIX/lib/httpd/modules/libphp.so"
		PHPIniDir "$PHP_INI"

		TypesConfig "$BREW_PREFIX/etc/httpd/mime.types"
		DirectoryIndex index.php index.html
		DocumentRoot "$dir/wordpress"

		<Directory "$dir/wordpress">
			Options FollowSymLinks
			AllowOverride All
			Require local
		</Directory>

		<FilesMatch \.php$>
			SetHandler application/x-httpd-php
		</FilesMatch>
	EOF

	"$HTTPD_PREFIX/bin/httpd" -f "$dir/httpd.conf" -k start
	wait_for "Apache on port $port" curl --silent --output /dev/null "http://localhost:$port/"
}

start_site() {
	local name="$1"
	[[ "$name" =~ ^[a-z][a-z0-9-]{0,19}$ ]] || fail "Site names are 1–20 lowercase letters, digits or dashes, starting with a letter."

	local dir
	dir="$(site_dir "$name")"
	[ -e "$dir" ] && fail "A site called '$name' already exists. Pick another name, or use \`$0 info $name\`."

	require_deps
	mkdir -p "$SITES_DIR" "$RUN_DIR" "$LOG_DIR"
	configure_php
	install_wp_cli
	ensure_database

	local port db password
	port="$(next_free_port)"
	db="wp_${name//-/_}"
	password="$(openssl rand -hex 12)"
	mkdir -p "$dir"
	local url="http://localhost:$port"

	mariadb_client <<-SQL
		CREATE DATABASE \`$db\`;
		CREATE USER '$db'@'localhost' IDENTIFIED BY '$password';
		CREATE USER '$db'@'127.0.0.1' IDENTIFIED BY '$password';
		GRANT ALL PRIVILEGES ON \`$db\`.* TO '$db'@'localhost';
		GRANT ALL PRIVILEGES ON \`$db\`.* TO '$db'@'127.0.0.1';
	SQL

	wp_cli core download --path="$dir/wordpress" --version="$WORDPRESS_VERSION" --quiet

	wp_cli config create \
		--path="$dir/wordpress" \
		--dbname="$db" \
		--dbuser="$db" \
		--dbpass="$password" \
		--dbhost="127.0.0.1:$DB_PORT" \
		--skip-check \
		--quiet \
		--extra-php <<-'PHP'
			# Allow application passwords over plain http
			define( 'WP_ENVIRONMENT_TYPE', 'local' );
			define( 'AUTOMATIC_UPDATER_DISABLED', true );
		PHP

	# The `.htaccess` the official `wordpress` Docker image ships with, so pretty
	# permalinks and the Authorization header (for application passwords) work.
	cat > "$dir/wordpress/.htaccess" <<-'HTACCESS'
		# BEGIN WordPress
		RewriteEngine On
		RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
		RewriteBase /
		RewriteRule ^index\.php$ - [L]
		RewriteCond %{REQUEST_FILENAME} !-f
		RewriteCond %{REQUEST_FILENAME} !-d
		RewriteRule . /index.php [L]
		# END WordPress
	HTACCESS

	local admin_password
	admin_password="$(openssl rand -hex 12)"
	wp_cli core install \
		--path="$dir/wordpress" \
		--url="$url" \
		--title="Test site $name" \
		--admin_user=admin \
		--admin_password="$admin_password" \
		--admin_email="admin@example.com" \
		--skip-email \
		--quiet
	wp_cli rewrite structure '/%postname%/' --path="$dir/wordpress" --quiet

	local app_password
	app_password="$(wp_cli user application-password create admin "Claude PR review" --porcelain --path="$dir/wordpress")"

	jq -n \
		--arg name "$name" --arg url "$url" --argjson port "$port" \
		--arg path "$dir/wordpress" --arg username admin \
		--arg password "$admin_password" --arg app_password "$app_password" \
		'{name: $name, url: $url, port: $port, path: $path, username: $username, password: $password, application_password: $app_password}' \
		> "$dir/site.json"

	start_web_server "$name"
	cat "$dir/site.json"
}

stop_site() {
	local name="$1"
	require_site "$name"
	local dir
	dir="$(site_dir "$name")"
	if [ -f "$dir/httpd.pid" ]; then
		"$HTTPD_PREFIX/bin/httpd" -f "$dir/httpd.conf" -k stop || true
	fi
}

case "${1:-}" in
	install-deps)
		brew install "$PHP_FORMULA" "$MARIADB_FORMULA" httpd jq
		;;
	start)
		[ $# -eq 2 ] || usage
		start_site "$2"
		;;
	wp)
		[ $# -ge 3 ] || usage
		require_site "$2"
		dir="$(site_dir "$2")"
		shift 2
		wp_cli --path="$dir/wordpress" "$@"
		;;
	info)
		[ $# -eq 2 ] || usage
		require_site "$2"
		cat "$(site_dir "$2")/site.json"
		;;
	list)
		for file in "$SITES_DIR"/*/site.json; do
			if [ -f "$file" ]; then jq -r '"\(.name)\t\(.url)"' "$file"; fi
		done
		;;
	stop)
		[ $# -eq 2 ] || usage
		stop_site "$2"
		;;
	*)
		usage
		;;
esac
