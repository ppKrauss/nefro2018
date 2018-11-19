
DROP TABLE IF EXISTS resumos.autores_homonimos_resp;
CREATE TABLE resumos.autores_homonimos_resp (
  perc_semelhanca int,
  usar text, -- to be int
  dif_12 text, nome1 text, nome2 text, correto text
);

COPY resumos.autores_homonimos_resp FROM '/tmp/nefro/autores_prova02b-homonimos-resp.csv' CSV HEADER;

CREATE VIEW resumos.vw_autores_homonimos_correcao AS
  WITH tbase AS (
    SELECT CASE WHEN usar='1' THEN nome2 ELSE nome1 END AS from_name,
           CASE WHEN usar='1' THEN nome1 ELSE nome2 END to_name,
           correto
    FROM resumos.autores_homonimos_resp
    WHERE usar IN ('1','2')
    ORDER BY 1,2
  ) SELECT DISTINCT t1.from_name,
        CASE WHEN lower(correto)='nao'
             THEN COALESCE(
               ( SELECT t2.to_name
                 FROM tbase t2
                 WHERE t2.from_name=t1.to_name AND lower(correto)!='nao'
               ),
               t1.to_name -- quebra galho: fica como estava se não achar
             )
             ELSE to_name
        END to_name
    FROM tbase t1
;
