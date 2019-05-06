# WordPress for iOS #

[![CircleCI](https://circleci.com/gh/wordpress-mobile/WordPress-iOS.svg?style=svg)](https://circleci.com/gh/wordpress-mobile/WordPress-iOS)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

## Build Instructions

### Download Xcode

At the moment *WordPress for iOS* uses Swift 4.2 and requires Xcode 10 or newer. Previous versions of Xcode can be [downloaded from Apple](https://developer.apple.com/downloads/index.action).*

### Third party tools

We use a few tools to help with development. To install or update the required dependencies, run the follow command on the command line:

`rake dependencies`

#### CocoaPods

WordPress for iOS uses [CocoaPods](http://cocoapods.org/) to manage third party libraries.  
Third party libraries and resources managed by CocoaPods will be installed by the `rake dependencies` command above.

#### SwiftLint

We use [SwiftLint](https://github.com/realm/SwiftLint) to enforce a common style for Swift code. The app should build and work without it, but if you plan to write code, you are encouraged to install it. No commit should have lint warnings or errors.

You can set up a Git [pre-commit hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) to run SwiftLint automatically when committing by running:

`rake git:install_hooks`

This is the recommended way to include SwiftLint in your workflow, as it catches lint issues locally before your code makes its way to Github.

Alternately, a SwiftLint scheme is exposed within the project; Xcode will show a warning if you don't have SwiftLint installed.

Finally, you can also run SwiftLint manually from the command line with:

`rake lint`

If your code has any style violations, you can try to automatically correct them by running:

`rake lint:autocorrect`

Otherwise you have to fix them manually.

### Open Xcode

Launch the workspace by running the following from the command line:

`rake xcode`

This will ensure any dependencies are ready before launching Xcode. 

You can also open the project by double clicking on WordPress.xcworkspace file, or launching Xcode and choose `File` > `Open` and browse to `WordPress.xcworkspace`.

### Setup Credentials

In order to login to WordPress.com using the app you will need to create an account over at the [WordPress.com Developer Portal](https://developer.wordpress.com).

After you created an account you can create an application on the [WordPress.com applications manager](https://developer.wordpress.com/apps/).

When creating your application, you should select "Native client" for the application type. The applications manager currently requires a "redirect URL", but this isn't used for mobile apps. Just use "https://localhost".

After you created an application you will have an associated a client ID and a client secret key. These details will be used to authenticate your application and verify that the API calls being made are valid. 

In order to use these details, you'll need to create a credential file in your build machine. Start by copying the sample credentials file to your home folder by doing this:

` mkdir -p ~/.mobile-secrets/iOS/WPiOS/ `

` cp ./WordPress/Credentials/wpcom_app_credentials.txt ~/.mobile-secrets/iOS/WPiOS/wpcom_app_credentials `

Then edit the `~/.mobile-secrets/iOS/WPiOS/wpcom_app_credentials` file and change the `WPCOM_APP_ID` and `WPCOM_APP_SECRET` fields to the values you got for your app.

Then you can compile and run the app on a device or an emulator and log in with a WordPress.com account.  Note that authenticating to WordPress.com via Google is not supported in development builds of the app, only in the official release.

**Remember the only account you will be able to login in with is the one affiliated with your developer account.** 

Read more about [OAuth2](https://developer.wordpress.com/docs/oauth2/) and the [WordPress.com REST endpoint](https://developer.wordpress.com/docs/api/).

## Contributing

Read our [Contributing Guide](CONTRIBUTING.md) to learn about reporting issues, contributing code, and more ways to contribute.

## Getting in Touch ##

If you have questions or just want to say hi, join the [WordPress Slack](https://chat.wordpress.org) and drop a message on the `#mobile` channel.

## Resources

- The [Wiki](https://github.com/wordpress-mobile/WordPress-iOS/wiki) contains information about our development practices.
- [WordPress Mobile Blog](http://make.wordpress.org/mobile)
- [WordPress Mobile Handbook](http://make.wordpress.org/mobile/handbook/)

## License

WordPress for iOS is an Open Source project covered by the [GNU General Public License version 2](LICENSE).
