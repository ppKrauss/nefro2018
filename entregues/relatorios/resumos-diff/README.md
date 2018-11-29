## Dump para verificacao de versoes

```sql
-- dump dos originais
SELECT file_put_contents(
   '/home/user/sandbox/nefro2018/entregues/relatorios/resumos-diff/'
   || (SELECT info->'modalidade'->>modalidade_aprovada FROM resumos.configs)  
   ||'.md'
   ,string_agg(  
      concat(E'\n## ',codigo,'. ',titulo, E'\n\n', autores, E'\n\n', resumo)
      ,  E'\n'
   )  
 ) 
FROM resumos.original 
group by modalidade_aprovada
;
```

```sh
sudo chown -R postgres.postgres resumos-diff/
# psql etc. com modificação da vez
sudo chown -R user.user resumos-diff/
```




