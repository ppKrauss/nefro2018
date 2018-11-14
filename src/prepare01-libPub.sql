
-- PUBLIC LIB

CREATE or replace FUNCTION xtag_a(
  p_title text,
  p_key text DEFAULT NULL,
  p_is_name boolean default true
) RETURNS xml AS $f$
  SELECT CASE
    WHEN p_is_name THEN xmlelement(  name a,  xmlattributes(rkey as name),  p_title  )
    ELSE xmlelement(  name a,  xmlattributes(rkey as href),  p_title  )
    END
  FROM (SELECT COALESCE( p_key, lower(unaccent(   regexp_replace(p_title,'[^\w]+','_','g')   )) )) t(rkey)
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION xtag_a_md5(
  p_title text,
  p_is_name boolean default true,
  p_trunc int DEFAULT 5
) RETURNS xml AS $f$
  SELECT xtag_a(p_title , substr(md5(p_title),1,p_trunc) , p_is_name)
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION array_distinct_sort (
  ANYARRAY,
  p_no_null boolean DEFAULT true
) RETURNS ANYARRAY AS $f$
  SELECT CASE WHEN array_length(x,1) IS NULL THEN NULL ELSE x END -- same as  x='{}'::anyarray
  FROM (
  	SELECT ARRAY(
        SELECT DISTINCT x
        FROM unnest($1) t(x)
        WHERE CASE
          WHEN p_no_null  THEN  x IS NOT NULL
          ELSE  true
          END
        ORDER BY 1
   )
 ) t(x)
$f$ language SQL strict IMMUTABLE;

-- FILE SYSTEM LIB:

CREATE or replace FUNCTION file_get_contents(p_file text) RETURNS text AS $f$
   with open(args[0],"r") as content_file:
       content = content_file.read()
   return content
$f$ LANGUAGE PLpythonU;  -- untrusted can read from any folder!

CREATE or replace FUNCTION file_put_contents(p_file text, p_content text) RETURNS text AS $f$
  # see https://stackoverflow.com/a/48485531/287948
  o=open(args[0],"w")
  o.write(args[1]) # no +"\n", no magic EOL
  o.close()
  return "ok"
$f$ LANGUAGE PLpythonU;

