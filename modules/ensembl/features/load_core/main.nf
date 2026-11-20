// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

nextflow.enable.types = true

process FEATURES_LOAD_CORE {
    tag "${meta.id}"
    label 'process_high'
    maxForks 1
    container 'docker.io/ensemblorg/ensembl-genomio:v1.9.0'
    container 'docker.io/library/mysql:8.4'

    secret 'CORE_DB_PASSWORD'
    secret 'PROD_DB_PASSWORD'

    input:
        record(
            meta: Map,
            features_json: Path,
            core_host: String,
            core_database: String,
            core_user: String,
            core_port: Integer,
            prod_host: String,
            prod_database: String,
            prod_user: String,
            prod_port: Integer,
            backup_before_load: Boolean,
        )

    stage:
        env 'BACKUP_FILENAME', meta.id
        env 'BACKUP_DB_HOST', core_host
        env 'BACKUP_DB_NAME', core_database
        env 'BACKUP_DB_USER', core_user
        env 'BACKUP_DB_PORT', "${core_port}"

    output:
        split = record(
            meta: meta,
            backups: files("*.sql.gz", optional: true)
        )

    topic:
        tuple(task.process, 'features_core_load', eval("features_core_load --version 2>/dev/null || echo unknown")) >> 'versions'

    script:
        def args = task.ext.args ?: ''

        def backup_script = '''
            (
                umask 077

                credentials=$(mktemp)
                trap 'rm -f -- "$credentials" "$BACKUP_FILENAME.part"' EXIT

                password=${CORE_DB_PASSWORD-}
                printf '[client]\\npassword="%s"\\n' "$password" > "$credentials"
                unset password CORE_DB_PASSWORD

                mysqldump --defaults-file="$credentials" --no-login-paths \\
                    --host="$BACKUP_DB_HOST" \\
                    --port="$BACKUP_DB_PORT" \\
                    --user="$BACKUP_DB_USER" \\
                    --no-tablespaces \\
                    --set-gtid-purged=OFF \\
                    --databases -- "$BACKUP_DB_NAME" \\
                    | gzip -c > "$BACKUP_FILENAME.part"

                mv -- "$BACKUP_FILENAME.part" "$BACKUP_FILENAME"
            )
        '''

        def load_script = """
            features_core_load --input-file "${features_json}" \\
                --core-host="\$BACKUP_DB_HOST" \\
                --core-database="\$BACKUP_DB_NAME" \\
                --core-user="\$BACKUP_DB_USER" \\
                --core-port="\$BACKUP_DB_PORT" \\
                --prod-host="${prod_host}" \\
                --prod-database="${prod_database}" \\
                --prod-user="${prod_user}" \\
                --prod-port="${prod_port}" \\
                ${args}
        """

        return 'set -euo pipefail\n' + (backup_before_load ? backup_script : '') + load_script

    stub:
        def backup_stub = backup_before_load ? '''
            printf '%s\\n' '-- Stub MySQL dump' | gzip -c > "$BACKUP_FILENAME"
        ''' : ''
        return 'set -euo pipefail\n' + backup_stub
}
