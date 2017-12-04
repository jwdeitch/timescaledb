CREATE OR REPLACE FUNCTION major_pg_version()
  RETURNS INTEGER
AS $$
DECLARE
  result INTEGER;
BEGIN
  EXECUTE 'SHOW server_version_num'
  INTO result;
  RETURN result;
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_pg10()
  RETURNS BOOL AS $$
SELECT CASE WHEN major_pg_version() > 10000
  THEN TRUE
       ELSE FALSE END AS is_pg10;
$$ LANGUAGE SQL;

SELECT is_pg10() as is_pg10
\gset
