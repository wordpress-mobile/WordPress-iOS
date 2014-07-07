WordPress for iOS

[![Build Status](https://travis-ci.org/wordpress-mobile/WordPress-iOS.png)](https://travis-ci.org/wordpress-mobile/WordPress-iOS)

## Resources

### Developer blog & Handbook

Blog: http://make.wordpress.org/mobile

Handbook: http://make.wordpress.org/mobile/handbook/

### Style guide

https://github.com/wordpress-mobile/WordPress-iOS/wiki/WordPress-for-iOS-Style-Guide

### To report an issue

https://github.com/wordpress-mobile/WordPress-iOS/issues

### Source Code

GitHub: https://github.com/wordpress-mobile/WordPress-iOS/

### How to Contribute

http://make.wordpress.org/mobile/handbook/pathways/ios/how-to-contribute/

## Building

Starting with changeset 3633 version 3.2, WordPress for iOS uses Cocoapods (http://cocoapods.org/) to manage third party libraries.  Trying to build the project by itself (WordPress.xcproj) after launching will result in an error, as the resources managed by cocoapods are not included.  Instead, launch the workspace by either double clicking on WordPress.xcworkspace file, or launch Xcode and choose File > Open and browse to WordPress.xcworkspace. 

In order to login to a WordPress.com account, you will need to create an account over at https://developer.wordpress.com. The only account you will be able to login in with is the one affiliated with your developer account. For more details see http://developer.wordpress.com/2014/07/04/authentication-improvements-for-testing-your-apps/.
