
##
# Make all (nefro2018).  Rodar com sudo:
#   sudo sh src/make.sh
##

cp recebidos/relatTrabalhos2018-08-18.csv  /tmp
cp entregues/relatorios/autores_prova02b-homonimos-resp.csv /tmp/nefro

php src/prepare02-toSql.php | psql postgres://postgres@localhost/test
psql postgres://postgres@localhost/test < src/get-resps.sql

cp /tmp/nefro/*.csv ./entregues/relatorios

