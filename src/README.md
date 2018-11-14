
## Preparo
Confira e edite as configurações do `toSql.php`. Exemplo:

```php
  $SCH = 'resumos';
  $tableRename='original';
  $modo='basico';  // basico|tudo|parcial
  $original = [
     'NEFRO2018-relatTrabalhos2018-08-30'=>'Código,Título,Resumo,Temário,Modalidade aprovada,E-mail,Instituição,Cidade,Estado,País,Autores'
  ];
  $original_conv = ['Código'=>'int'];
``` 

Todas as tabelas e funções do esquema `resumos`  serão reinicializados pelo comando 
```sh
cd nefro2018 # root of the git
php src/prepare02-toSql.php | psql postgres://postgres@localhost/test
```

Ignorar mensagens tais como *"ERRO:  extensão 'file_fdw' já existe"*. Exemplo de resultado:
```
DROP SCHEMA
CREATE SCHEMA
DROP FOREIGN TABLE
CREATE FOREIGN TABLE
CREATE TABLE
INSERT 0 740
```

Conforme configurada a variavel `$modo`  o SQL se apresentará de forma mais simples ou mais completa.

### Modo basico
Utilizado para prospecção ou usos incompativeis. Apenas gera a tabela de dados filtrados do CSV no PostgreSQL.
 
### Modo parcial
.. inclui a libPub

### Modo tudo
...

## Processando

```sql
COPY (SELECT codigo, titulo, e_mail, instituicao, cidade FROM resumos.original) 
  TO '/tmp/prova01-metadados.csv' CSV HEADER;
```

### Check-emails

No `psql`  rodar 
```SQL
SELECT codigo, e_mail FROM resumos.original WHERE lower(e_mail) !~ '^[a-z0-9_\-\.]+@';
COPY (
  SELECT DISTINCT lower(regexp_replace(regexp_split_to_table(e_mail, '[\s,;]+'), '^[^@]+@', '')) e_mail  
  FROM resumos.original
  ORDER BY 1
) TO '/tmp/prova02-domains.csv' CSV;
```
que deve retornar zero registros para a primeira 
consulta &mdash; caso contrário a listagem será indicativo de falha ou e-mail suspeito &mdash;, 
e o comando COPY deve retornar o número de registros, algo como "COPY 48". 

Em seguida, para complementar a verificação dos e-mails através da confirmação MX-records dos supostos domínios, no terminal rodar 
```sh
php src/check_domain_MX.php < /tmp/prova02-domains.csv 
```

### Check-autores

```sql
CREATE VIEW resumos.vw_autores_relat01 AS
  SELECT lower(unaccent(regexp_replace(regexp_split_to_table(trim(autores), '\s*;[;\s]*'), '^[^@]+@', ''))) autor
         ,count(*) n, array_agg(codigo ORDER BY codigo) as codigos
  FROM resumos.original
  GROUP BY 1
  ORDER BY 1;

COPY (select * from resumos.vw_autores_relat01 WHERE autor>'') 
  TO '/tmp/autores_prova01.csv' CSV HEADER;
  -- COPY 2813
```

### Demais relatórios para inspeção

```sql 
SELECT modalidade_aprovada, count(*) n
FROM resumos.original group by 1 order by 1;
```
Exemplo de resultado:

modalidade_aprovada |  n  
---------------------|-----
 Apresentação Oral   |  59
 Jovem Pesquisador   |   6
 Pôster Comentado    |  62
 Pôster Eletrônico   | 613

Se uma das modalidades apresentar quantidade relativa muito baixa, pode ser indicativo de, por exemplo, falha ortográfica.
