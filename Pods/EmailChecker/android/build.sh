ndk-build clean
rm -rf libs
gradle build
mvn install:install-file -Dfile=build/libs/EmailChecker-0.1-debug.aar -DgroupId=org.wordpress -DartifactId=emailchecker -Dpackaging=aar -Dversion=0.1
