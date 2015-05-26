<?php

if ( count( $argv ) < 2 ) {
	die("Usage: php fix-translation.php Localizable.strings\n");
}
array_shift( $argv );

foreach ( $argv as $file ) {
	$f = fopen( $file, 'r+' );
	$out = '';
	while ( $line = fgets( $f ) ) {
		$utf8Line = mb_convert_encoding( $line, 'UTF-8', 'UTF-16BE' );
		if ( preg_match( '/^"(.*)" = "";$/', $utf8Line, $matches ) ) {
			$fixedLine = preg_replace( '/^"(.*)" = "";$/', '"$1" = "$1";', $utf8Line );
			$fixedLine = mb_convert_encoding( $fixedLine, 'UTF-16BE' );
			$out .= $fixedLine;
		} else if ( preg_match('/^(.* = ".*)(?<!\\\\)\"(.*)(?<!\\\\)\"(.*\";)$/uim', $utf8Line, $matches ) ) {
			$fixedLine = preg_replace('/^(.* = ".*)(?<!\\\\)\"(.*)(?<!\\\\)\"(.*\";)$/uim', '$1\\"$2\\"$3', $utf8Line);
			$fixedLine = mb_convert_encoding( $fixedLine, 'UTF-16BE', 'UTF-8' );
			$out .= $fixedLine;
		} else {
			$out .= $line;
		}
	}
	fseek( $f, 0, SEEK_SET );
	fwrite( $f, $out );
	fclose( $f );
}

?>
