# Debezium Issue Reproducer: DateTimeParseException with `pgoutput` Plugin

## Issue Overview

I'm encountering an issue with Debezium version 2.3.1 while processing a snapshot from a PostgreSQL database. The error occurs during the snapshot phase and seems to be related to parsing a date/time value. The specific error message is:
```shell
Caused by: org.apache.kafka.connect.errors.ConnectException:
java.time.format.DateTimeParseException: Text 'f' could not be parsed at index 0
at io.debezium.connector.postgresql.connection.DateTimeFormat$ISODateTimeFormat.format(DateTimeFormat.java:166)
at io.debezium.connector.postgresql.connection.DateTimeFormat$ISODateTimeFormat.timestampToInstant(DateTimeFormat.java:172)
at io.debezium.connector.postgresql.connection.AbstractColumnValue.asInstant(AbstractColumnValue.java:81)
at io.debezium.connector.postgresql.connection.ReplicationMessageColumnValueResolver.resolveValue(ReplicationMessageColumnValueResolver.java:110)
at io.debezium.connector.postgresql.connection.pgoutput.PgOutputReplicationMessage.getValue(PgOutputReplicationMessage.java:92)
at io.debezium.connector.postgresql.connection.pgoutput.PgOutputMessageDecoder$1.getValue(PgOutputMessageDecoder.java:748)
at io.debezium.connector.postgresql.PostgresChangeRecordEmitter.columnValues(PostgresChangeRecordEmitter.java:179)
at io.debezium.connector.postgresql.PostgresChangeRecordEmitter.getNewColumnValues(PostgresChangeRecordEmitter.java:125)
at io.debezium.relational.RelationalChangeRecordEmitter.emitCreateRecord(RelationalChangeRecordEmitter.java:69)
at io.debezium.relational.RelationalChangeRecordEmitter.emitChangeRecords(RelationalChangeRecordEmitter.java:47)
at io.debezium.connector.postgresql.PostgresChangeRecordEmitter.emitChangeRecords(PostgresChangeRecordEmitter.java:94)
at io.debezium.pipeline.EventDispatcher.dispatchDataChangeEvent(EventDispatcher.java:296)
... 17 more
Caused by: java.time.format.DateTimeParseException: Text 'f' could not be parsed at index 0
at java.base/java.time.format.DateTimeFormatter.parseResolved0(DateTimeFormatter.java:2046)
at java.base/java.time.format.DateTimeFormatter.parse(DateTimeFormatter.java:1874)
at io.debezium.connector.postgresql.connection.DateTimeFormat$ISODateTimeFormat.lambda$timestampToInstant$3(DateTimeFormat.java:172)
at io.debezium.connector.postgresql.connection.DateTimeFormat$ISODateTimeFormat.format(DateTimeFormat.java:162)
```

## Environment Details

- **Debezium PostgreSQL Connector Version:** 2.3.1
- **PostgreSQL Version:** 13.15
- **Deployment Environment:** Google Kubernetes Engine (GKE)
- **Plugin:** `pgoutput`

## Connector Configuration

```json
{
  "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
  "connector.displayName": "PostgreSQL",
  "database.user": "docker",
  "database.dbname": "exampledb",
  "transforms": "unwrap",
  "database.server.name": "localhost",
  "heartbeat.interval.ms": "60000",
  "database.port": "5432",
  "plugin.name": "pgoutput",
  "slot.max.retries": "10",
  "schema.include.list": "public",
  "slot.retry.delay.ms": "15000",
  "heartbeat.action.query": "INSERT INTO public.debezium_heartbeat VALUES ('debezium', now())",
  "decimal.handling.mode": "string",
  "database.hostname": "postgres",
  "database.password": "docker",
  "transforms.unwrap.drop.tombstones": "false",
  "signal.data.collection": "public.debezium_signal",
  "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
  "table.include.list": "public.table, public.debezium_signal",
  "max.batche.size": "65000",
  "max.queue.size": "275000",
  "incremental.snapshot.chunk.size": "6500",
  "connector.id": "postgres",
  "topic.prefix": "db-prod"
}
```

## DDL table 

```sql
CREATE TABLE IF NOT EXISTS public.table
(
    id bigint NOT NULL DEFAULT nextval('table_id_seq'::regclass),
    federal_tax_id character varying(255) COLLATE pg_catalog."default",
    external_id character varying(255) COLLATE pg_catalog."default",
    first_name character varying(255) COLLATE pg_catalog."default",
    last_name character varying(255) COLLATE pg_catalog."default",
    email character varying(255) COLLATE pg_catalog."default",
    phone character varying(255) COLLATE pg_catalog."default",
    cellphone character varying(255) COLLATE pg_catalog."default",
    address_street character varying(255) COLLATE pg_catalog."default",
    address_street_number character varying(255) COLLATE pg_catalog."default",
    address_complement character varying(255) COLLATE pg_catalog."default",
    address_city_district character varying(255) COLLATE pg_catalog."default",
    address_post_code character varying(255) COLLATE pg_catalog."default",
    address_city character varying(255) COLLATE pg_catalog."default",
    address_city_code character varying(255) COLLATE pg_catalog."default",
    address_state_code character varying(255) COLLATE pg_catalog."default",
    address_country character varying(255) COLLATE pg_catalog."default",
    address_latitude numeric,
    address_longitude numeric,
    address_geo geometry(Point,4326) GENERATED ALWAYS AS (st_setsrid(st_makepoint((address_longitude)::double precision, (address_latitude)::double precision), 4326)) STORED,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_company boolean NOT NULL DEFAULT false,
    state_tax_id character varying(255) COLLATE pg_catalog."default",
    official_name character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT table_pkey PRIMARY KEY (id)
)
TABLESPACE pg_default;
```

### When I started snapshot I received this payload:

```json
{
    "payload": {
        "id": 28948709,
        "federal_tax_id": "XXX.XXX.XXX-XX",
        "external_id": "extXXXXXX",
        "first_name": "Nome da Empresa",
        "last_name": "N/A",
        "email": "contato@dominio.com",
        "phone": "+55 XX XXXXX-XXXX",
        "cellphone": "+55 XX XXXXX-XXXX",
        "address_street": "Rua Exemplo",
        "address_street_number": "XX",
        "address_complement": "Complemento Exemplo",
        "address_city_district": "Bairro Exemplo",
        "address_post_code": "XXXXX-XXX",
        "address_city": "Cidade Exemplo",
        "address_city_code": "XXXX",
        "address_state_code": "XX",
        "address_country": "BR",
        "address_latitude": "-XX.XXXX",
        "address_longitude": "-XX.XXXX",
        "address_geo": {
            "wkb": "AQEAACDmEAAARUdy+Q9RR8CwcmiR7Yw3wA==",
            "srid": 4326
        },
        "created_at": 1722989773163,
        "updated_at": 1723386966400,
        "is_company": true,
        "state_tax_id": "XX123456789",
        "official_name": "Nome da Empresa"
    }
}

```
### When I did a update on table I receveid this payload:
```json
{
    "payload": {
        "id": 28948707,
        "federal_tax_id": "XXX.XXX.XXX-XX",
        "external_id": "extXXXXXX",
        "first_name": "Nome",
        "last_name": "Sobrenome",
        "email": "usuario@dominio.com",
        "phone": "+55 XX XXXXX-XXXX",
        "cellphone": "+55 XX XXXXX-XXXX",
        "address_street": "Avenida Exemplo",
        "address_street_number": "XX",
        "address_complement": "Sala XXX",
        "address_city_district": "Bairro Exemplo",
        "address_post_code": "XXXXX-XXX",
        "address_city": "Cidade Exemplo",
        "address_city_code": "XXXX",
        "address_state_code": "XX",
        "address_country": "BR",
        "address_latitude": "-XX.XXXX",
        "address_longitude": "-XX.XXXX",
        "created_at": 1722990056975,
        "updated_at": 1723406879566,
        "is_company": false,
        "state_tax_id": "XX987654321",
        "official_name": "Nome Sobrenome"
    }
}

```

## Log Analysis
Upon encountering the error, I reviewed the logs and discovered that the address_geo column received an incorrect value:
```shell
2024-08-12 10:03:13,233 TRACE  Postgres|company-db-prod|streaming  Column: address_latitude(numeric)=-22.9068   [io.debezium.connector.postgresql.connection.pgoutput.PgOutputMessageDecoder]
2024-08-12 10:03:13,233 TRACE  Postgres|company-db-prod|streaming  Column: address_longitude(numeric)=-43.1729   [io.debezium.connector.postgresql.connection.pgoutput.PgOutputMessageDecoder]
2024-08-12 10:03:13,233 TRACE  Postgres|company-db-prod|streaming  Column: address_geo(geometry)=2024-08-07 00:20:56.975735   [io.debezium.connector.postgresql.connection.pgoutput.PgOutputMessageDecoder]
```

## Analysis and Testing
I upgraded Debezium to versions 2.7.0.Final, 2.7.1.Final, and 3.0.0.Alpha2 using the same connector, but the issue persisted. Testing with the tutorial using DEBEZIUM_VERSION=2.7 and the standard connector with decoderbufs plugin didn't reproduce the issue. This suggests that the problem might be related to some functionality linked to pgoutput.
## Reproducing the Issue
To reproduce the issue, follow these steps:

 1. Ensure the Debezium tutorial repository is in the same directory as this file.
 2. Run step by step the shell script reproduce_issue.sh.


## For more details check the discussion
[Stackoverflow](https://stackoverflow.com/questions/78845761/issue-with-debezium-snapshot-datetimeparseexception-in-postgresql-connector)
[Debezium Community](https://debezium.zulipchat.com/#narrow/stream/348249-community-postgresql/topic/Issue.20with.20Debezium.20Snapshot.3A.20DateTimeParseException.20in.20Post)

## Jira issue open to fix this bug
[Jira Debezium](https://issues.redhat.com/browse/DBZ-8150)

## Release fix the problem
[Debezium 3.0.0.Beta Released](https://debezium.io/blog/2024/08/26/debezium-3.0-beta1-released/)