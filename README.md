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

### Cocoapods

Starting with changeset 3633 version 3.2, WordPress for iOS uses Cocoapods (http://cocoapods.org/) to manage third party libraries.  Trying to build the project by itself (WordPress.xcproj) after launching will result in an error, as the resources managed by cocoapods are not included.

Run `pod install` from the command line to install dependencies for the project.

*The current version of CocoaPods is recommended.*

### Xcode

Launch the workspace by either double clicking on WordPress.xcworkspace file, or launch Xcode and choose File > Open and browse to WordPress.xcworkspace.

*WordPress for iOS requires Swift 2.0 and Xcode 7.0 or newer. Previous versions of Xcode can be [downloaded from Apple](https://developer.apple.com/downloads/index.action).*

More information on building the project and the tools required can be found in [the handbook](https://make.wordpress.org/mobile/handbook/pathways/ios/tools-requirements/).

## Logging in

In order to login to a WordPress.com account, you will need to create an account over at https://developer.wordpress.com. The only account you will be able to login in with is the one affiliated with your developer account. Once you have an account and a corresponding app id and app secret, you will need to setup a ~/.wpcom_app_credentials file as detailed [here](http://make.wordpress.org/mobile/handbook/pathways/ios/tutorials-guides/#3-%c2%a0setup-wpcom_app_credentials). For more details see http://developer.wordpress.com/2014/07/04/authentication-improvements-for-testing-your-apps/.

## License

WordPress for iOS is an Open Source project covered by the [GNU General Public License version 2](LICENSE).
