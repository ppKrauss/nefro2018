
##
# Make all (nefro2018).  Rodar com sudo:
#   sudo sh src/make.sh
##

cp lix  /tmp/relatTrabalhos2018-08-18.csv
php src/prepare02-toSql.php | psql postgres://postgres@localhost/test
cp /tmp/nefro/*.csv ./entregues/relatorios

