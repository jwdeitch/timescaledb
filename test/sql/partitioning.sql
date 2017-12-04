CREATE TABLE part_legacy(time timestamptz, temp float, device int);
SELECT create_hypertable('part_legacy', 'time', 'device', 2, partitioning_func => '_timescaledb_internal.get_partition_for_key');

-- Show legacy partitioning function is used
SELECT * FROM _timescaledb_catalog.dimension;

INSERT INTO part_legacy VALUES ('2017-03-22T09:18:23', 23.4, 1);
INSERT INTO part_legacy VALUES ('2017-03-22T09:18:23', 23.4, 76);

VACUUM part_legacy;

-- Show two chunks and CHECK constraint with cast
SELECT * FROM test.show_constraintsp('_timescaledb_internal._hyper_1_%_chunk');

-- Make sure constraint exclusion works on device column
EXPLAIN (verbose, costs off)
SELECT * FROM part_legacy WHERE device = 1;

CREATE TABLE part_new(time timestamptz, temp float, device int);
SELECT create_hypertable('part_new', 'time', 'device', 2);

SELECT * FROM _timescaledb_catalog.dimension;

INSERT INTO part_new VALUES ('2017-03-22T09:18:23', 23.4, 1);
INSERT INTO part_new VALUES ('2017-03-22T09:18:23', 23.4, 2);

VACUUM part_new;

-- Show two chunks and CHECK constraint without cast
SELECT * FROM test.show_constraintsp('_timescaledb_internal._hyper_2_%_chunk');

-- Make sure constraint exclusion works on device column
EXPLAIN (verbose, costs off)
SELECT * FROM part_new WHERE device = 1;

CREATE TABLE part_new_convert1(time timestamptz, temp float8, device int);
SELECT create_hypertable('part_new_convert1', 'time', 'temp', 2);

INSERT INTO part_new_convert1 VALUES ('2017-03-22T09:18:23', 1.0, 2);
\set ON_ERROR_STOP 0
-- Changing the type of a hash-partitioned column should not be supported
ALTER TABLE part_new_convert1 ALTER COLUMN temp TYPE numeric;
\set ON_ERROR_STOP 1

-- Should be able to change if not hash partitioned though
ALTER TABLE part_new_convert1 ALTER COLUMN time TYPE timestamp;

SELECT * FROM test.show_columnsp('_timescaledb_internal._hyper_3_%_chunk');

CREATE TABLE part_add_dim(time timestamptz, temp float8, device int, location int);
SELECT create_hypertable('part_add_dim', 'time', 'temp', 2);

\set ON_ERROR_STOP 0
SELECT add_dimension('part_add_dim', 'location', 2, partitioning_func => 'bad_func');
\set ON_ERROR_STOP 1

SELECT add_dimension('part_add_dim', 'location', 2, partitioning_func => '_timescaledb_internal.get_partition_for_key');
SELECT * FROM _timescaledb_catalog.dimension;

-- Should expect an error when creating a hypertable from a partition
\set ON_ERROR_STOP 0
CREATE TABLE partitioned_ht_create(time timestamptz, temp float, device int) PARTITION BY RANGE (time);
SELECT create_hypertable('partitioned_ht_create', 'time');
\set ON_ERROR_STOP 1

-- Should expect an error when attaching a hypertable to a partition
\set ON_ERROR_STOP 0
CREATE TABLE partitioned_attachment_vanilla(time timestamptz, temp float, device int) PARTITION BY RANGE (time);
CREATE TABLE attachment_hypertable(time timestamptz, temp float, device int);
SELECT create_hypertable('attachment_hypertable', 'time');
ALTER TABLE partitioned_attachment_vanilla ATTACH PARTITION attachment_hypertable FOR VALUES FROM ('2016-07-01') TO ('2016-08-01');
\set ON_ERROR_STOP 1

-- Should not expect an error when attaching a normal table to a partition
CREATE TABLE partitioned_vanilla(time timestamptz, temp float, device int) PARTITION BY RANGE (time);
CREATE TABLE attachment_vanilla(time timestamptz, temp float, device int);
ALTER TABLE partitioned_vanilla ATTACH PARTITION attachment_vanilla FOR VALUES FROM ('2016-07-01') TO ('2016-08-01');