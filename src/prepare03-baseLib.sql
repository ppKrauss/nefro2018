
CREATE VIEW resumos.vw_autores_relat01_unicos AS
  SELECT lower(unaccent(regexp_split_to_table(trim(autores,' ;.,'), '\s*;[;\s]*'))) autor
         ,count(*) n
         , array_agg(codigo ORDER BY codigo) as codigos
  FROM resumos.original
  GROUP BY 1
  ORDER BY 1
;

CREATE VIEW resumos.vw_autores_relat02_homonimos AS
   SELECT first, last, array_agg(autor_trm) autores
   FROM (
     SELECT metaphone(partes[1],5) as first
            ,metaphone(array_last_butnot(
              partes,
              array['junior','jr','jr.','filho','filha','neto','neta']
            ),5) as last
            ,autor_trm
     FROM (
       SELECT regexp_split_to_array(autor_trm,' ') partes,
              autor_trm
       FROM resumos.vw_autores_relat01_unicos u,
       LATERAL (SELECT trim(u.autor,' .,;')) t0(autor_trm)
       ORDER BY 1
     ) t1
     ORDER BY 1,2,3
   ) t2
   GROUP BY 1,2
   HAVING count(*)>1
   ORDER BY 1,2
;
