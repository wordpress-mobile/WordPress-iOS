WordPress for iOS

## Resources

### Developer blog

http://dev.ios.wordpress.org/

### Style guide

https://github.com/wordpress-mobile/WordPress-iOS/wiki/WordPress-for-iOS-Style-Guide

### To report an issue

http://ios.trac.wordpress.org/newticket

You'll need a WordPress.org account. If you don't have one you can
register here:

http://wordpress.org/support/register.php

### Source Code

SVN: http://ios.svn.wordpress.org/

SVN browser: http://ios.trac.wordpress.org/browser

Github mirror: https://github.com/wordpress-mobile/WordPress-iOS/

## Building

Starting with changeset 3633 version 3.2, WordPress for iOS uses Cocoapods (http://cocoapods.org/) to manage third party libraries.  Trying to build the project by itself (WordPress.xcproj) after launching will result in an error, as the resources managed by cocoapods are not included.  Instead, launch the workspace by either double clicking on WordPress.xcworkspace file, or launch Xcode and choose File > Open and browse to WordPress.xcworkspace. 


