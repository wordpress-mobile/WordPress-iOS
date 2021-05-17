<?php

/// Validate arguments
if( ! isset($argv[1]) ) {
	die("You must provide a filename argument");
}

$file = $argv[1];

/// Get dependencies
require_once __DIR__ . '/po.php';

/// Validate the provided file
$parts = pathinfo( $file );
if ( 'po' === $parts['extension'] || 'pot' === $parts['extension'] ) {
	$po     = new PO();
	$result = $po->import_from_file( $file );

	if ( false === $result ) {
		echo 'Invalid localization file';
		exit(1);
	}
}

echo 'Localization file is valid';
