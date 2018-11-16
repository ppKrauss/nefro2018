
-- PUBLIC LIB

CREATE EXTENSION IF NOT EXISTS unaccent;      -- for unaccent()
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch; -- for metaphone() and  levenshtein()
CREATE EXTENSION IF NOT EXISTS plpythonu;     -- for Python2

-- array functions

CREATE or replace FUNCTION array_last(
  p_input anyarray
) RETURNS anyelement AS $f$
  SELECT $1[array_upper($1,1)]
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION array_last_butnot(
  p_input anyarray,
  p_not anyarray
) RETURNS anyelement AS $f$
  SELECT CASE
     WHEN array_length($1,1)<2 THEN   $1[array_lower($1,1)]
     WHEN p_not IS NOT NULL AND thelast=any(p_not) THEN   $1[x-1]
     ELSE thelast
     END
  FROM (select x,$1[x] thelast FROM (select array_upper($1,1)) t(x)) t2
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION array_last_butnot(p_input anyarray,p_not anyelement) RETURNS anyelement AS $wrap$
  SELECT array_last_butnot($1,array[$2])
$wrap$ LANGUAGE SQL IMMUTABLE;

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

-- XML functions

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

-- FILE SYSTEM LIB:

CREATE or replace FUNCTION file_mkdir(p_dir text) RETURNS text AS $f$
  # v1.0
  import os
  # dir = os.path.dirname(args[0])
  if not os.path.exists(args[0]):
      os.makedirs(args[0])
  return args[0]
$f$ LANGUAGE PLpythonU STRICT;

CREATE or replace FUNCTION file_get_contents(p_file text) RETURNS text AS $f$
   # v1.0
   with open(args[0],"r") as content_file:
       content = content_file.read()
   return content
$f$ LANGUAGE PLpythonU STRICT;  -- untrusted can read from any folder!


CREATE or replace FUNCTION file_put_contents(
  p_file text,
  p_content text,
  p_msg text DEFAULT ' (file "%s" saved!) '
) RETURNS text AS $$
  o=open(args[0],"w")
  o.write(args[1])
  o.close()
  if args[2] and args[2].find('%s')>0 :
    return (args[2] % args[0])
  else:
    return args[2]
$$ LANGUAGE PLpythonU STRICT;

----

CREATE or replace FUNCTION strings_to_diff(
  p_a text, -- input string not null
  p_b text  -- input string not null
) RETURNS text[] AS $f$
  import difflib
  d = difflib.Differ()
  return list(d.compare( unicode(args[0],"utf-8"), unicode(args[1],"utf-8") ))
$f$ LANGUAGE PLpythonU STRICT;

CREATE or replace FUNCTION strings_to_diff_formated(
  p_a text, p_b text,
  p_placeholder text DEFAULT NULL, -- NULL=html else something as '?'
  p_use_bold boolean DEFAULT true
) RETURNS text AS $f$
  SELECT string_agg(CASE
    WHEN p='  ' THEN upper(x)
    WHEN p='+ ' THEN CASE
      WHEN p_placeholder is not null THEN p_placeholder
      ELSE concat(opb,'<ins>',x,'</ins>',clb)
      END
    WHEN p='- ' THEN CASE
      WHEN p_placeholder is not null THEN p_placeholder
      ELSE concat(opb,'<del>',x,'</del>',clb)
      END
    END, '')
  FROM unnest(strings_to_diff($1,$2)) t1(c),
       LATERAL (SELECT substr(t1.c,1,2), substr(t1.c,3),
       CASE WHEN p_use_bold THEN '<b>' ELSE '' END,
       CASE WHEN p_use_bold THEN '</b>' ELSE '' END
     ) t2(p,x,opb,clb)
$f$ language SQL immutable;


CREATE or replace FUNCTION unnest_2d_1d(
  ANYARRAY, OUT a ANYARRAY
) RETURNS SETOF ANYARRAY AS $func$
 BEGIN
    -- https://stackoverflow.com/a/41405177/287948
    -- IF $1 = '{}'::int[] THEN ERROR END IF;
    FOREACH a SLICE 1 IN ARRAY $1 LOOP
       RETURN NEXT;
    END LOOP;
 END
$func$ LANGUAGE plpgsql IMMUTABLE STRICT;

-----

CREATE or replace FUNCTION array_levenshtein_perc(
	p_input text[],
	p_cut float DEFAULT 0.2,  -- ou 0.05 mais semelhantes ainda.
  p_useLess boolean DEFAULT true,  -- usa less-words como criterio
  p_sep text DEFAULT ' '   -- separador de palavras
) RETURNS text[] AS $f$
  -- rets s[1] perc_semelhantes, s[2] dif_12, s[3] nome1, s[4] nome2
  WITH items(item,i) AS (
    SELECT * FROM (
      SELECT * FROM unnest($1) WITH ORDINALITY i
    ) t0(item,i)
    ORDER BY length(item), item
  )
  SELECT array_agg(array[
    to_char( round(100.0*(1-perc)), 'fm000' ),
    strings_to_diff_formated( a_i, b_i, '?' ),
    a_i,
    b_i
  ] ORDER BY perc DESC)
  FROM (
    SELECT a.item as a_i, b.item as b_i,
         levenshtein(a.item,b.item)::float / greatest(length(a.item), length(b.item)) perc
    FROM items a, items b
    WHERE a.i>b.i -- triangular superior
  ) t
  WHERE perc < p_cut
     OR (p_useLess AND
       (string_char_occurs(a_i,p_sep)=1 OR string_char_occurs(b_i,p_sep)=1)
       AND perc<p_cut*2.0
     )
$f$ LANGUAGE SQL IMMUTABLE;
