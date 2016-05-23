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

We use a few tools to help with development. To install or update the required dependencies, run `rake dependencies` from the command line.

### CocoaPods

WordPress for iOS uses CocoaPods (http://cocoapods.org/) to manage third party libraries.  Trying to build the project by itself (WordPress.xcproj) after launching will result in an error, as the resources managed by CocoaPods are not included.

Run `rake dependencies` from the command line to install dependencies for the project. This will ensure the current supported version of CocoaPods is used. If you have the same version installed in your system, you can also run `pod install`.

### SwiftLint

We use [SwiftLint](https://github.com/realm/SwiftLint) to enforce a common style for Swift code. Xcode will show a warning if you don't have it installed. The app should build and work without it, but if you plan to write code, you are encouraged to install it. No commit should have lint warnings or errors.

SwiftLint runs automatically when you build the project, but you can run it manually from the command line with `rake lint`

If your code has any style violations, you can try to automatically correct them by running `rake lint:autocorrect`. Otherwise you have to fix them manually.

### Xcode

Launch the workspace by running `rake xcode` from the command line. This will ensure any dependencies are ready before launching Xcode. You can also open the project by double clicking on WordPress.xcworkspace file, or launching Xcode and choose File > Open and browse to WordPress.xcworkspace.

*WordPress for iOS requires Swift 2.2 and Xcode 7.3 or newer. Previous versions of Xcode can be [downloaded from Apple](https://developer.apple.com/downloads/index.action).*

More information on building the project and the tools required can be found in [the handbook](https://make.wordpress.org/mobile/handbook/pathways/ios/tools-requirements/).

## Logging in

In order to login to a WordPress.com account, you will need to create an account over at https://developer.wordpress.com. The only account you will be able to login in with is the one affiliated with your developer account. Once you have an account and a corresponding app id and app secret, you will need to setup a ~/.wpcom_app_credentials file as detailed [here](http://make.wordpress.org/mobile/handbook/pathways/ios/tutorials-guides/#3-%c2%a0setup-wpcom_app_credentials). For more details see http://developer.wordpress.com/2014/07/04/authentication-improvements-for-testing-your-apps/.

## License

WordPress for iOS is an Open Source project covered by the [GNU General Public License version 2](LICENSE).
