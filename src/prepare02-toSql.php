<?php
/**
 * Alinha material fornecido e gera XML a partir do PostgreSQL.
 * Permite uso de SQL intermediário para debug. Modo de usar:
 *   cp data/*.csv /tmp
 *   php src/toSql.php | psql "postgresql://postgres:postgres@localhost:5432/trydatasets"
 * Ver resultado parcial em /tmp/resumos2018.xml ou geral em /tmp/resumos*.htm
 * Ver sh make.sh para reconstrução dos HTMLs.
 */

// // // // //
// CONFIGS:
  $SCH = 'resumos';
  $tableRename='original';
  $modo='basico';  // basico|tudo|parcial

  $original = [
     'NEFRO2018-relatTrabalhos2018-08-30'=>'Código,Título,Resumo,Temário,Modalidade aprovada,E-mail,Instituição,Cidade,Estado,País,Autores'
  ];
  $original_conv = ['Código'=>'int'];

// // // // //
$original_conv_flag = (count($original_conv)>0);
$sql1 = $sql2 = $sql3 = '';
foreach ($original as $k=>$fields) {
	$f = "olds/$k.csv";
	$linha0 = fgets(fopen($f, 'r'));
	// print "\n\n-- $f = $fields\n\t= $linha0";
	$fields0 = [];
	$field0_names = [];
	foreach( explode(',',$linha0) as $r) {
		$r = trim($r);
		$field0_names[] = "\"$r\"";
		$fields0[] = "\"$r\" text";
	}
	$join_fields0 = join(", ",$fields0);
        $k2 = $tableRename? $tableRename: $k;
	$sql1 .= <<<EOT
DROP FOREIGN TABLE IF EXISTS tmpcsv_$k2 CASCADE;
CREATE FOREIGN TABLE tmpcsv_$k2 (
	$join_fields0
) SERVER files OPTIONS (
	filename '/tmp/$k.csv',
	format 'csv',
	header 'true'
);
EOT;
	$sql1 .= "\n";
	$types = [];
	$fields1 = [];
	foreach( explode(',',$fields) as $r) {
		$r = trim($r);
		$p = mb_strrpos($r,' ');
		if ($original_conv_flag && isset($original_conv[$r])) {
			$types[] = $original_conv[$r];
			$fields1[] = pg_varname($r)." $original_conv[$r]";
		} elseif ($original_conv_flag || $p===false) {
			$types[] = 'text';
			$fields1[] = pg_varname($r)." text";
		} else {
			$fields1[] = $r;
			$r0 = pg_varname(mb_substr($r,0,$p)); //on bug: check that mb is UTF8
			$types[] = mb_substr($r,$p+1);
		}
	}
	$fields1 = join(", ",$fields1);
	$sql2 .=  "\nCREATE TABLE $SCH.$k2 (\n\t$fields1);";
	$map = [];
	for ($i=0; $i<count($field0_names); $i++)
		$map[] = " trim($field0_names[$i])::$types[$i]";
	$sql2 .=  "\nINSERT INTO $SCH.$k2 SELECT ".join(',',$map)." FROM tmpcsv_$k2;\n\n";
        $sql3 .= "\nDROP FOREIGN TABLE tmpcsv_$k2 CASCADE;";
}


////
// TRECHO FORA DE USO, $csvFields from datapackage fora de uso, ver array originais
//  $j =json_decode(file_get_contents('datapackage.json'), JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
//  $csvFields = $j['resources'][0]['schema']['fields'];
//  print 'DEBUG:'.json_encode($csvFields, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
////

// Abaixo output com SQL que pode ser usado como script intermediário para debugs.
?>

-- cp data/*.csv /tmp

CREATE EXTENSION file_fdw;
CREATE SERVER files FOREIGN DATA WRAPPER file_fdw;

<?php print "DROP SCHEMA IF EXISTS $SCH CASCADE; CREATE SCHEMA $SCH;" ?>

<?php print "$sql1\n\n------\n\n$sql2\n\n-----\n$sql3" ?>

<?php if ($modo!='basico'):

 include 'src/prepare01-libPub.sql' ?>

<?php endif;
      if ($modo=='tudo'):
?>

SELECT file_put_contents(
      '/tmp/resumos2018.xml',
      replace(
         xmlelement( name dumps,  xmlagg(x) )::text,
         '<article-dump',
         E'\n\n<article-dump'
      )
    )
FROM resumos.vw_relxml1;

-- Indice da Capa:
SELECT file_put_contents(
  '/tmp/resumos2018_capa.htm',
  xmlconcat(
    resumos.sumario('Oral'),
    resumos.sumario('Pôster'),
    (select xmlelement(name p, 'Total geral '|| (SELECT count(*) FROM resumos.reltrabalhos) || ' resumos' ))
    )::text
  );

-- Indice dos autores:
SELECT file_put_contents(
  '/tmp/resumos2018_idx.htm',
  replace(
    xmlagg( xmlelement(
      name p,
      (autor ||'...'|| array_to_string(itens,', '))::xml
    ))::text,
    '<p',
    E'\n<p'
   ) -- replace
 ) -- file
FROM (
  SELECT
    name_for_index(nome_full) autor,
    array_agg( xtag_a(r.pub_id, '#'||replace(r.pub_id,chr(160),''), false)::text ) itens
  FROM resumos.relTrabalhos r,
       LATERAL jsonb_to_recordset( (resumos.metadata_bycod(r.codigo))->'contribs' ) t(nome_full text)
  GROUP BY 1
  ORDER BY 1
) t;


SELECT file_put_contents(
      '/tmp/resumos2018_body.htm',
      regexp_replace(
         xmlelement( name div,  fullbody )::text,
         '(<p|<section|<div|<h)',
         E'\n\\1',
         'g'
      )--regexp_replace
    )
FROM resumos.vw_body;

<?php
endif;

// // // LIB

function pg_varname($s,$toAsc=true) {
  if ($toAsc) //  universal variable-name:
    return strtolower( preg_replace('#[^\w0-9]+#s', '_', iconv('utf-8','ascii//TRANSLIT',$s)) );
  else //  reasonable column name:
    return mb_strtolower( preg_replace('#[^\p{L}0-9\-]+#su', '_', $s), 'UTF-8' );
}

?>

