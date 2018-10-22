FROM postgres:alpine
ENV PGDATA /var/lib/pgcluster/data
RUN echo "#!/bin/sh" > /slave.sh && \
    echo "if [[ -z \"\${REPLIC_USER}\" ]]; then" >> /slave.sh && \
    echo "    export REPLIC_USER=replication" >> /slave.sh && \
    echo "fi" >> /slave.sh && \
    echo "if [[ -z \"\${REPLIC_PASSWORD}\" ]]; then" >> /slave.sh && \
    echo "    export REPLIC_PASSWORD=toto" >> /slave.sh && \
    echo "fi" >> /slave.sh && \
    echo "if [[ -z \"\${SERVER_TYPE}\" ]]; then" >> /slave.sh && \
    echo "    echo \"Env variable SERVER_TYPE isn't defined\"" >> /slave.sh && \
    echo "    exit 1" >> /slave.sh && \
    echo "fi" >> /slave.sh && \
    echo "if [[ -z \"\${SLAVE_IP}\" ]]; then" >> /slave.sh && \
    echo "    echo \"Env variable SLAVE_IP isn't defined\"" >> /slave.sh && \
    echo "    exit 1" >> /slave.sh && \
    echo "fi" >> /slave.sh && \
    echo "if [[ -z \"\${SLAVE_PORT}\" ]]; then" >> /slave.sh && \
    echo "    echo \"Env variable SLAVE_PORT isn't defined\"" >> /slave.sh && \
    echo "    exit 1" >> /slave.sh && \
    echo "fi" >> /slave.sh && \
    echo "if [[ -z \"\${POSTGRES_DB}\" ]]; then" >> /slave.sh && \
    echo "    export POSTGRES_DB=toto" >> /slave.sh && \
    echo "fi" >> /slave.sh && \
    echo "if [ \$SERVER_TYPE = \"SLAVE\" ]; then" >> /slave.sh && \
    echo "    if [[ -z \"\${MASTER_IP}\" ]]; then" >> /slave.sh && \
    echo "        echo \"Env variable MASTER_IP isn't defined\"" >> /slave.sh && \
    echo "        exit 1" >> /slave.sh && \
    echo "    fi" >> /slave.sh && \
    echo "    if [[ -z \"\${MASTER_PORT}\" ]]; then" >> /slave.sh && \
    echo "        echo \"Env variable MASTER_PORT isn't defined\"" >> /slave.sh && \
    echo "        exit 1" >> /slave.sh && \
    echo "    fi" >> /slave.sh && \
    echo "fi" >> /slave.sh && \
    echo "if [ ! -s \"\$PGDATA/PG_VERSION\" ]; then" >> /slave.sh && \
    echo "    echo \"Initialize Version\"" >> /slave.sh && \
    echo "    mkdir -p ~/postgresql" >> /slave.sh && \
    echo "    echo \"*:*:*:\$REPLIC_USER:\$REPLIC_PASSWORD\" > ~/.pgpass" >> /slave.sh && \
    echo "    chmod 600 ~/.pgpass" >> /slave.sh && \
    echo "    if [ \$SERVER_TYPE = \"MASTER\" ]; then" >> /slave.sh && \
    echo "        echo \"Try to init master from a slave\"" >> /slave.sh && \
    echo "        pg_basebackup -U \$REPLIC_USER -h \$SLAVE_IP -p \$SLAVE_PORT -v -P -X fetch -D \$PGDATA" >> /slave.sh && \
    echo "        if [ \$? = 0 ]; then" >> /slave.sh && \
    echo "            rm \$PGDATA/recovery.conf" >> /slave.sh && \
    echo "            echo \"Init from slave OK, start server\"" >> /slave.sh && \
    echo "            rm -Rf ~/postgresql" >> /slave.sh && \
    echo "        else" >> /slave.sh && \
    echo "            echo \"Init from slave ERROR, create master from scratch\"" >> /slave.sh && \
    echo "            rm -Rf ~/postgresql" >> /slave.sh && \
    echo "            echo \"sed -i 's;#wal_level = replica;wal_level = replica ;g' $PGDATA/postgresql.conf\" > /docker-entrypoint-initdb.d/master.sh" >> /slave.sh  && \
    echo "            echo \"sed -i 's;#wal_keep_segments = 0;wal_keep_segments = 256;g' $PGDATA/postgresql.conf\" >> /docker-entrypoint-initdb.d/master.sh" >> /slave.sh  && \
    echo "            echo \"sed -i 's;#hot_standby = on;hot_standby = on ;g' $PGDATA/postgresql.conf\" >> /docker-entrypoint-initdb.d/master.sh" >> /slave.sh && \
    echo "            echo \"psql -U \$POSTGRES_USER -c \\\"CREATE USER \$REPLIC_USER REPLICATION LOGIN CONNECTION LIMIT 1 ENCRYPTED PASSWORD '\$REPLIC_PASSWORD';\\\" \$POSTGRES_DB\" >> /docker-entrypoint-initdb.d/master.sh" >> /slave.sh && \
    echo "            echo \"psql -U \$POSTGRES_USER -c \\\"ALTER ROLE \$REPLIC_USER CONNECTION LIMIT 5;\\\" \$POSTGRES_DB\" >> /docker-entrypoint-initdb.d/master.sh" >> /slave.sh && \
    echo "            echo \"echo \\\"host replication replication all md5\\\" >> $PGDATA/pg_hba.conf\" >> /docker-entrypoint-initdb.d/master.sh" >> /slave.sh && \
    echo "        fi" >> /slave.sh && \
    echo "    else" >> /slave.sh && \
    echo "        echo \"Try to init slave from a master\"" >> /slave.sh && \
    echo "        pg_basebackup -U \$REPLIC_USER -h \$MASTER_IP -p \$MASTER_PORT -v -P -X fetch -D \$PGDATA" >> /slave.sh && \
    echo "        if [ \$? = 0 ]; then" >> /slave.sh && \
    echo "            echo \"Init from master OK, start server\"" >> /slave.sh && \
    echo "            rm -Rf ~/postgresql" >> /slave.sh && \
    echo "            echo \"standby_mode = 'on'\" > \$PGDATA/recovery.conf" >> /slave.sh && \
    echo "            echo \"primary_conninfo = 'user=''\$REPLIC_USER'' password=''\$REPLIC_PASSWORD'' host=''\$MASTER_IP'' port=\$MASTER_PORT sslmode=prefer sslcompression=1 target_session_attrs=any'\" >> \$PGDATA/recovery.conf" >> /slave.sh && \
    echo "        else" >> /slave.sh && \
    echo "            echo \"Init from master ERROR, stop server\"" >> /slave.sh && \
    echo "            rm -Rf ~/postgresql" >> /slave.sh && \
    echo "            exit 1" >> /slave.sh && \
    echo "        fi" >> /slave.sh && \
    echo "    fi" >> /slave.sh && \
    echo "else" >> /slave.sh && \
    echo "    echo \"Restore Version\"" >> /slave.sh && \
    echo "    if [ \$SERVER_TYPE = \"MASTER\" ]; then" >> /slave.sh && \
    echo "        echo \"Restore master from slave\"" >> /slave.sh && \
    echo "        mv \$PGDATA \$PGDATA.save" >> /slave.sh && \
    echo "        mkdir -p ~/postgresql" >> /slave.sh && \
    echo "        echo \"*:*:*:\$REPLIC_USER:\$REPLIC_PASSWORD\" > ~/.pgpass" >> /slave.sh && \
    echo "        chmod 600 ~/.pgpass" >> /slave.sh && \
    echo "        pg_basebackup -U \$REPLIC_USER -h \$SLAVE_IP -p \$SLAVE_PORT -v -P -X fetch -D \$PGDATA" >> /slave.sh && \
    echo "        if [ \$? = 0 ]; then" >> /slave.sh && \
    echo "            rm \$PGDATA/recovery.conf" >> /slave.sh && \
    echo "            echo \"Restore from slave OK, start server\"" >> /slave.sh && \
    echo "            rm -Rf ~/postgresql" >> /slave.sh && \
    echo "            rm -Rf \$PGDATA.save" >> /slave.sh && \
    echo "        else" >> /slave.sh && \
    echo "            echo \"Restore from slave ERROR, start master with current datas\"" >> /slave.sh && \
    echo "            rm -Rf ~/postgresql" >> /slave.sh && \
    echo "            rm -Rf \$PGDATA" >> /slave.sh && \
    echo "            mv \$PGDATA.save \$PGDATA" >> /slave.sh && \
    echo "        fi" >> /slave.sh && \
    echo "    else" >> /slave.sh && \
    echo "        echo \"Start slave server...\"" >> /slave.sh && \
    echo "    fi" >> /slave.sh && \
    echo "fi" >> /slave.sh && \
    echo "docker-entrypoint.sh postgres" >> /slave.sh && \
    chmod +x /slave.sh
CMD "/slave.sh"
