# postgres-cluster
If you have your VM where you db master which fall, so you can't recreate another db master with old datas. With this image you can deploy a Slave and a Master, slave will only replicate master datas, and master will try to be intialized with slave data, and else will initialize from scratch.

Warn : PGDATA is intentionally moved (i've used /var/lib/pgcluster) because image postgres:alpine defined data folder as volume by default, and to reinitialize cluster we must move data folder (so we me map to docker volume parent of data folder). It's the reason why, in the example, volumes is to data parent folder and not data folder

Exemple of stack:

- Add a label "pgstack=slave" on nodes to run the slave server
- Add a label "pgstack=master" on other nodes

=> The goal is to force swarm to not deploy slave and master on same nodes

Content of the stack:

```
version: '3.6'

services:
  pgmaster:
    image: "Chklang/postgres-cluster"
    environment:
      - SERVER_TYPE=MASTER
      - SLAVE_IP=pgslave
      - SLAVE_PORT=5432
      - POSTGRES_USER=**USER**
      - POSTGRES_PASSWORD=**PASSWORD**
    ports:
      - 5432
    volumes:
      - pgdata_master:/var/lib/pgcluster
    deploy:
      placement:
        constraints:
          - "node.labels.pgstack==master"
    networks:
      subnet:

  pgslave:
    image: "Chklang/postgres-cluster"
    environment:
      - SERVER_TYPE=SLAVE
      - SLAVE_IP=pgslave
      - SLAVE_PORT=5432
      - MASTER_IP=pgmaster
      - MASTER_PORT=5432
    ports:
      - 5432
    volumes:
      - pgdata_slave:/var/lib/pgcluster
    deploy:
      placement:
        constraints:
          - "node.labels.pgstack==slave"
    networks:
      subnet:

networks:
  subnet:
    external: true

volumes:
  pgdata_master:
  pgdata_slave:
```

After, search the docker node where you have the master, do a "docker ps" to found the ID, do a "docker exec -i <DOCKER_ID> sh" and type:
```
psql -U **USER** postgres
```
to connect to database and create user/roles/databases
