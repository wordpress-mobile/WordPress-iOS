<?php 
// This script help you build a PR based on a specific gutenberg-mobile commit. 
// Which then can be used to create a iOS build.
// To use the script call it from the WordPress-iOS repo root directory.
// php Scripts/create-GB-mobile-pr.php --commit= {specific git hash}

// Get the script arguments.
$arguments = getopt( '', array( 'commit:' ) );

if ( empty( $arguments['commit'] ) ) {
    echo '[Fail] No commit argument was passed, try adding --commit= to the command';
    echo PHP_EOL;
    die();
} 
$commit = $arguments['commit'];
$github_commit_url = 'https://github.com/wordpress-mobile/gutenberg-mobile/commit/' . $commit;
$github_headers = get_headers($github_commit_url, 1);

$time_start = microtime(true);

if( ! strpos( $github_headers[0] , '200' ) !== false ) {
    echo "[Fail] Commit: {$commit} is not a valid commit hash.";
    echo PHP_EOL;
    echo "Requested {$github_commit_url} - Response: {$github_headers[0]}";
    echo PHP_EOL;
    echo PHP_EOL;
    die();
} else {
    echo "[OK] Commit: {$commit} is valid commit" . PHP_EOL;
    echo "See: {$github_commit_url}" . PHP_EOL;
}
echo PHP_EOL; 

$repo_root_directory = realpath( __DIR__ . "/../" );
$temp_directory =  $repo_root_directory . "/../temp-wp-ios-gutenberg-mobile-{$commit}";

$repo_context = "cd {$repo_root_directory}";
$temp_context = "cd {$temp_directory} ";
// echo shell_exec( "cd {$repo_root_dir} " . PHP_EOL );

// 1. Create new Worktree
$branch_name = "try/test-build-gb-mobile-{$commit}";

$output_add_worktree = shell_exec ( $repo_context . " && git worktree add -b '{$branch_name}' {$temp_directory} develop" );
print( $output_add_worktree . PHP_EOL );
echo "[OK] New working tree created" . PHP_EOL;

// 3. Update the podfile. 
update_podfile( $commit, $temp_directory . '/Podfile' );

// 4. Update dependencies
print( '[OK] Updating dependencies with rake dependencies, this can take a while.' );
echo PHP_EOL; // Intentional to leave out some space.
echo PHP_EOL; 
$output_update_dependencies = shell_exec( "{$temp_context} && rake dependencies" );
print( $output_update_dependencies . PHP_EOL );
$finished_dependencies_time = format_time( microtime(true) - $time_start );
print( "[OK] Updated dependencies in {$finished_dependencies_time} in seconds." );
echo PHP_EOL;

// 5. commit changes..
print(  shell_exec( "{$temp_context} &&  git status" ) . PHP_EOL );
$output_commit = shell_exec( "{$temp_context} && git commit -a -m 'Test: Creating iOS build of GB Mobile commit {$commit}' ");
print( $output_commit . PHP_EOL );

// 6. Push the changes to github.
$push_branch = shell_exec( "{$temp_context} && git push --set-upstream origin {$branch_name}");
print( $push_branch . PHP_EOL );
echo PHP_EOL; 

// 7. Clean up 
// its important to delete the worktree first
print( shell_exec( "{$repo_context} && git worktree remove {$temp_directory}") );
echo "[OK] Deleted worktree in {$temp_directory}" . PHP_EOL;

print( shell_exec( "{$repo_context} && git branch -d {$branch_name}") );
echo "[OK] Deleted local branch" . PHP_EOL;

// END
echo '[Done] To finish up the process you need to create a new PR.';
echo PHP_EOL; 
echo "By visiting https://github.com/wordpress-mobile/WordPress-iOS/pull/new/{$branch_name} to complete the process.";
echo PHP_EOL; 

$finished_time = format_time( microtime(true) - $time_start );
echo "- Script finished in {$finished_time} seconds";
echo PHP_EOL; 

// remote the 

function replace_podfile_content( $contents, $commit ) {
    $podfile_lines = explode( PHP_EOL, $contents );
    $update_line_to = "\tgutenberg :commit => '{$commit}'";

    foreach( $podfile_lines as $key => $line ) {
        // find the line to update.
        if ( strpos( $line, 'gutenberg :commit ' ) !== false ) {
            $podfile_lines[ $key ] = $update_line_to;
            echo '[OK] Replaced line ' .  $line . ' with ' . $update_line_to . PHP_EOL;
            continue;
        }

        if ( strpos( $line, 'gutenberg :tag ') !== false ) {
            $podfile_lines[$key] = $update_line_to;
            echo '[OK] Replaced line ' .  $line . ' with ' . $update_line_to . PHP_EOL;
            continue;
        }
    }
    return implode( PHP_EOL, $podfile_lines );
}

function update_podfile( $commit, $new_podfile ) {
    $podfile = __DIR__ . '/../Podfile';
    $contents = file_get_contents ( $podfile );

    if ( empty( $contents ) ) {
        echo '[Fail] Podfile content is empty' ;
        die();
    }
    $new_content = replace_podfile_content( $contents, $commit );

    if ( file_put_contents ( $new_podfile, $new_content ) ) {
        echo "[OK] Updated Podfile... {$new_podfile}" . PHP_EOL;
    }
}

function format_time( $time ) {
    $minutes = floor($time / 60);
    $time -= $minutes * 60;

    $seconds = floor($time);
    $time -= $seconds;

    return "{$minutes}m {$seconds}s";
}

