<?php
/**
 * Confere existência de MX nos domínios listados. Garante minimamente a existencia de um e-mail.
 * Baseado em http://php.net/manual/en/function.checkdnsrr.php
 */


foreach(file('php://stdin') as $r) {
  $r = trim($r);
  $check = checkdnsrr($r,'MX')? "domain MX ok": "!!! FAIL on domain MX !!!";
  print "\n--- $r: $check";
}
?>

