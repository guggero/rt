#!/bin/bash

# Postgres init scripts: https://github.com/docker-library/docs/tree/master/postgres#initialization-scripts
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER loop WITH PASSWORD 'loop';
    CREATE DATABASE loop;
    GRANT ALL PRIVILEGES ON DATABASE loop TO loop;

    CREATE USER pool WITH PASSWORD 'pool';
    CREATE DATABASE pool;
    GRANT ALL PRIVILEGES ON DATABASE pool TO pool;
    
    CREATE USER taprootassets WITH PASSWORD 'taprootassets';
    CREATE DATABASE taprootassets;
    GRANT ALL PRIVILEGES ON DATABASE taprootassets TO taprootassets;
EOSQL
