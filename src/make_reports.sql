/**
 * Make CSV and JSON reports.
 */

select file_mkdir('/tmp/nefro');

---- METADADOS ----

COPY (SELECT codigo, titulo, e_mail, instituicao, cidade FROM resumos.original)
  TO '/tmp/nefro/prova01-metadados.csv' CSV HEADER;

----  EMAIL ------

COPY (
  SELECT DISTINCT lower(regexp_replace(regexp_split_to_table(e_mail, '[\s,;]+'), '^[^@]+@', '')) e_mail
  FROM resumos.original
  ORDER BY 1
) TO '/tmp/nefro/prova02-domains.csv' CSV;

--- AUTORES -----

COPY (select * from resumos.vw_autores_relat01_unicos WHERE autor>'')
  TO '/tmp/nefro/autores_prova01-todos.csv' CSV HEADER
;  -- COPY 2813

COPY (
  select first, last, array_to_string(autores,'|') autores
  from resumos.vw_autores_relat02_homonimos)
  TO '/tmp/nefro/autores_prova02a-suspeitos.csv' CSV HEADER
;  -- COPY 243

COPY (
  SELECT s[1] perc_semelhanca, '' usar, s[2] dif_12, s[3] nome1, s[4] nome2
  FROM (
    SELECT unnest_2d_1d(suspeitos) s
    FROM (
      SELECT array_levenshtein_perc(autores,0.2) suspeitos
      FROM resumos.vw_autores_relat02_homonimos
    ) t0
    WHERE suspeitos IS NOT NULL
    ORDER BY 1 DESC
  ) t1
) TO '/tmp/nefro/autores_prova02b-homonimos.csv' CSV HEADER
; -- 108
