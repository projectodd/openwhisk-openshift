#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -e

export HOME=/opt/couchdb

if [ "$1" = '/opt/couchdb/bin/couchdb' ]; then

	if [ ! -z "$NODENAME" ] && ! grep "couchdb@" /opt/couchdb/etc/vm.args; then
		echo "-name couchdb@$NODENAME" >> /opt/couchdb/etc/vm.args
	fi

  if [ ! -z "$COUCHDB_SECRET" ] && ! grep "setcookie" /opt/couchdb/etc/vm.args; then
    echo "-setcookie $COUCHDB_SECRET" >> /opt/couchdb/etc/vm.args
  fi

  INI_FILE=/opt/couchdb/etc/local.d/openshift.ini
  printf "[query_server_config]\n%s = %s\n" "reduce_limit" "false" > $INI_FILE
  printf "[compactions]\n%s = %s\n" "_default" "[{db_fragmentation, \"35%\"}, {view_fragmentation, \"40%\"}]" >> $INI_FILE

	if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ]; then
    # Admin user
		printf "[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_PASSWORD" >> $INI_FILE
    # Bind to 0.0.0.0  
    printf "[chttpd]\n%s = %s\n" "bind_address" "0.0.0.0" >> $INI_FILE
    printf "[httpd]\n%s = %s\n" "bind_address" "any" >> $INI_FILE
	fi

  if [ "$COUCHDB_NODE_COUNT" -gt "1" ]; then
    printf "[cluster]\n%s = %s\n" "n" "$COUCHDB_NODE_COUNT" >> $INI_FILE
  fi

	# if we don't find an [admins] section followed by a non-comment, display a warning
	if ! grep -Pzoqr '\[admins\]\n[^;]\w+' /opt/couchdb/etc/local.d/*.ini; then
		# The - option suppresses leading tabs but *not* spaces. :)
		cat >&2 <<-'EOWARN'
			****************************************************
			WARNING: CouchDB is running in Admin Party mode.
			         This will allow anyone with access to the
			         CouchDB port to access your database. In
			         Docker's default configuration, this is
			         effectively any other container on the same
			         system.
			         Use "-e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password"
			         to set it in "docker run".
			****************************************************
		EOWARN
	fi

	exec "$@"
fi

exec "$@"
