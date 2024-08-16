# Terminal 1 - start the deployment
# Start the deployment
export DEBEZIUM_VERSION=2.7
docker-compose -f docker-compose-postgres.yaml up
# Terminal 2
# Create a signalling table
echo "CREATE TABLE inventory.dbz_signal (id varchar(64), type varchar(32), data varchar(2048))" | docker-compose -f docker-compose-postgres.yaml exec -T postgres env PGOPTIONS="--search_path=inventory" bash -c "psql -U $POSTGRES_USER postgres"
# Start Postgres connector, capture only customers table and enable signalling
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://localhost:8083/connectors/ -d @- <<EOF
{
    "name": "inventory-connector",
    "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "tasks.max": "1",
        "database.hostname": "postgres",
        "database.port": "5432",
        "database.user": "postgres",
        "database.password": "postgres",
        "database.dbname": "postgres",
        "database.server.name": "dbserver1",
        "schema.include": "inventory",
        "table.include.list": "inventory.customers,inventory.dbz_signal",
        "signal.data.collection": "inventory.dbz_signal",
        "topic.prefix": "dbserver1" ,
        "plugin.name": "pgoutput"
    }
}
EOF
# Terminal 2
# Create a inventory.table_test
echo "
DROP EXTENSION IF EXISTS postgis;
SET search_path TO inventory;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SEQUENCE IF NOT EXISTS inventory.table_test_id_seq;
CREATE TABLE IF NOT EXISTS inventory.table_test (
    id bigint NOT NULL DEFAULT nextval('inventory.table_test_id_seq'::regclass),
    federal_tax_id character varying(255) COLLATE pg_catalog.\"default\",
    external_id character varying(255) COLLATE pg_catalog.\"default\",
    first_name character varying(255) COLLATE pg_catalog.\"default\",
    last_name character varying(255) COLLATE pg_catalog.\"default\",
    email character varying(255) COLLATE pg_catalog.\"default\",
    phone character varying(255) COLLATE pg_catalog.\"default\",
    cellphone character varying(255) COLLATE pg_catalog.\"default\",
    address_street character varying(255) COLLATE pg_catalog.\"default\",
    address_street_number character varying(255) COLLATE pg_catalog.\"default\",
    address_complement character varying(255) COLLATE pg_catalog.\"default\",
    address_city_district character varying(255) COLLATE pg_catalog.\"default\",
    address_post_code character varying(255) COLLATE pg_catalog.\"default\",
    address_city character varying(255) COLLATE pg_catalog.\"default\",
    address_city_code character varying(255) COLLATE pg_catalog.\"default\",
    address_state_code character varying(255) COLLATE pg_catalog.\"default\",
    address_country character varying(255) COLLATE pg_catalog.\"default\",
    address_latitude numeric,
    address_longitude numeric,
    address_geo geometry(Point,4326) GENERATED ALWAYS AS (st_setsrid(st_makepoint((address_longitude)::double precision, (address_latitude)::double precision), 4326)) STORED,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_at timestamp without time zone NOT NULL DEFAULT now(),
    is_company boolean NOT NULL DEFAULT false,
    state_tax_id character varying(255) COLLATE pg_catalog.\"default\",
    official_name character varying(255) COLLATE pg_catalog.\"default\",
    CONSTRAINT table_test_pkey PRIMARY KEY (id)
);" | docker-compose -f docker-compose-postgres.yaml exec -T postgres bash -c "psql -U \$POSTGRES_USER -d postgres"
# TERMINAL 2
# Insert fake data into inventory.table_test
echo "
INSERT INTO inventory.table_test (federal_tax_id, external_id, first_name, last_name, email, phone, cellphone, address_street, address_street_number, address_complement, address_city_district, address_post_code, address_city, address_city_code, address_state_code, address_country, address_latitude, address_longitude, created_at, updated_at, is_company, state_tax_id, official_name)
VALUES
('12345678901', 'EXT001', 'Luke', 'Skywalker', 'luke.skywalker@example.com', '555-1234', '555-5678', '123 Force Lane', '1', 'Apt 1', 'Jedi District', '12345', 'Tatooine', 'TAT', 'TAT', 'Tatooine', 34.0522, -118.2437, now(), now(), false, 'TAT98765', 'Jedi Order'),
('98765432109', 'EXT002', 'Leia', 'Organa', 'leia.organa@example.com', '555-8765', '555-4321', '456 Rebel Ave', '2', 'Suite 2', 'Rebel District', '54321', 'Alderaan', 'ALD', 'ALD', 'Alderaan', 40.7128, -74.0060, now(), now(), false, 'ALD54321', 'Rebel Alliance'),
('12398745601', 'EXT003', 'Han', 'Solo', 'han.solo@example.com', '555-3456', '555-6789', '789 Smuggler Road', '3', 'Floor 3', 'Smuggler District', '67890', 'Corellia', 'COR', 'COR', 'Corellia', 37.7749, -122.4194, now(), now(), false, 'COR12345', 'Millennium Falcon Co.'),
('32165498702', 'EXT004', 'Obi-Wan', 'Kenobi', 'obi.wan.kenobi@example.com', '555-9876', '555-5432', '101 Jedi Temple', '4', 'Unit 4', 'Temple District', '24680', 'Kamino', 'KAM', 'KAM', 'Kamino', 22.3964, 114.1095, now(), now(), false, 'KAM24680', 'Jedi Council'),
('65432109876', 'EXT005', 'Yoda', 'Master', 'yoda.master@example.com', '555-6543', '555-2109', '202 Green Swamp', '5', 'Green House', 'Swamp District', '13579', 'Dagobah', 'DAG', 'DAG', 'Dagobah', -21.2860, 149.1261, now(), now(), false, 'DAG13579', 'Jedi Masters Inc.')
;" | docker-compose -f docker-compose-postgres.yaml exec -T postgres bash -c "psql -U \$POSTGRES_USER -d postgres"
# TERMINAL 2
#add table inventory.tabela_test in table.include.list
curl -i -X PUT -H "Accept:application/json" -H "Content-Type:application/json" http://localhost:8083/connectors/inventory-connector/config -d @- <<EOF
{
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres",
    "database.dbname" : "postgres",
    "database.server.name": "dbserver1",
    "schema.include": "inventory",
    "table.include.list": "inventory.customers,inventory.dbz_signal,inventory.table_test ",
    "signal.data.collection": "inventory.dbz_signal",
     "topic.prefix": "dbserver1",
   "plugin.name": "pgoutput"
}
EOF
# TERMINAL 2
# Start incremental snapshot
echo "INSERT INTO inventory.dbz_signal VALUES ('signal-1', 'execute-snapshot', '{\"data-collections\": [\"inventory.table_test\"]}')" | docker-compose -f docker-compose-postgres.yaml exec -T postgres env PGOPTIONS="--search_path=inventory" bash -c "psql -U $POSTGRES_USER postgres"
# Terminal 3
# update into inventory.tabela_test in the same time of snapshot
echo "
UPDATE inventory.table_test
SET updated_at = current_timestamp
WHERE federal_tax_id = '12345678901';
" | docker-compose -f docker-compose-postgres.yaml exec -T postgres bash -c "psql -U \$POSTGRES_USER -d postgres"
#OR
#insert into inventory.table_test in the same time of snapshot
echo "
INSERT INTO inventory.table_test (federal_tax_id, external_id, first_name, last_name, email, phone, cellphone, address_street, address_street_number, address_complement, address_city_district, address_post_code, address_city, address_city_code, address_state_code, address_country, address_latitude, address_longitude, created_at, updated_at, is_company, state_tax_id, official_name)
VALUES
('11122334455', 'EXT006', 'Mace', 'Windu', 'mace.windu@example.com', '555-6789', '555-4321', '789 Jedi Way', '6', 'Unit 6', 'Jedi District', '13579', 'Geonosis', 'GEO', 'GEO', 'Geonosis', -10.2860, 123.4567, now(), now(), false, 'GEO12345', 'Jedi Order'),
('22233445566', 'EXT007', 'Padmé', 'Amidala', 'padme.amidala@example.com', '555-5432', '555-8765', '456 Naboo Lane', '7', 'Suite 7', 'Naboo District', '24680', 'Naboo', 'NAB', 'NAB', 'Naboo', 32.7767, -96.7970, now(), now(), false, 'NAB54321', 'Naboo Senate')
;" | docker-compose -f docker-compose-postgres.yaml exec -T postgres bash -c "psql -U \$POSTGRES_USER -d postgres"