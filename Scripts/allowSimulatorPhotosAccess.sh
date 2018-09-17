#!/usr/bin/perl
$currentUserID = `id -un`;
chomp($currentUserID);
$folderLocations = `find "/Users/$currentUserID/Library/Developer/CoreSimulator/Devices" -name TCC`;
print "currentUserID: $currentUserID\n\n";

while($folderLocations =~ /(..*)/g) {
    print "folder: $1\n";
    `sqlite3 "$1/TCC.db" "insert into access values('kTCCServicePhotos','org.wordpress', 0, 1, 1, null, null)"`;
    print "\n";
}
