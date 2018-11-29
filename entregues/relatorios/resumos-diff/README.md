lembrar


2 digits base32 encodes exactly the same as 5 digits base4.

So for each 1 base32 we need seil(2.5*digits) 

===

0. Passar tudo para doc.md  para análise no Github.
1. Conferir fontes
2. Gerar lista de links autores em ordem sobrenome
3. Listar todas as solicitaçoes.
4. 

===

## Dump para verificacao de versoes

```sql

SELECT file_put_part(
     (SELECT info->'modalidade'->>modalidade_aprovada FROM resumos.configs),  
     array_agg( concat(E'\n## ',codigo,'. ',titulo, E'\n\n', autores, E'\n\n', resumo) )
   )
FROM (select *, row_number() OVER (PARTITION BY modalidade_aprovada) ct from resumos.original) t
GrOUP BY  modalidade_aprovada
;
```

```sh
sudo chown -R postgres.postgres resumos-diff/
# psql etc. com modificação da vez
sudo chown -R user.user resumos-diff/
```
