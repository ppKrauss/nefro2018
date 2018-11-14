
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
