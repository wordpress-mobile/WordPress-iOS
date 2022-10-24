# WordPress for iOS #

[![Build status](https://badge.buildkite.com/2f3fbb17bfbb5bba508efd80f1ea8d640db5ca2465a516a457.svg)](https://buildkite.com/automattic/wordpress-ios)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

## Build Instructions

Please refer to the sections below for more detailed information. The instructions assume the work is performed from a command line.

> Please note – these setup instructions only apply to Intel-based machines. M1-based Mac support is coming, but isn't yet supported by our tooling.

### Getting Started

1. [Download](https://developer.apple.com/downloads/index.action) and install Xcode. *WordPress for iOS* requires Xcode 11.2.1 or newer.
1. From a command line, run `git clone git@github.com:wordpress-mobile/WordPress-iOS.git` in the folder of your preference.
1. Now, run `cd WordPress-iOS` to enter the working directory.

#### Create WordPress.com API Credentials

1. Create a WordPress.com account at https://wordpress.com/start/user (if you don't already have one).
1. Create an application at https://developer.wordpress.com/apps/.
1. Set "Redirect URLs"= `https://localhost` and "Type" = `Native` and click "Create" then "Update".
1. Copy the `Client ID` and `Client Secret` from the OAuth Information.

#### Configure Your WordPress App Development Environment

1. Check that your local version of Ruby matches the one in [.ruby-version](./.ruby-version). We recommend installing a tool like [rbenv](https://github.com/rbenv/rbenv) so your system will always use the version defined in that file. Once installed, simply run `rbenv install` in the repo to match the version.
1. Return to the command line and run `rake init:oss` to configure your computer and WordPress app to be able to run and login to WordPress.com
1. Once completed, run `rake xcode` to open the project in Xcode.

If all went well you can now compile to your iOS device or simulator, and log into the WordPress app.

Note: You can only log in with the WordPress.com account that you used to create the WordPress application.

## Configuration Details

The steps above will help you configure the WordPress app to run and compile.  But you may sometimes need to update or re-run specific parts of the initial setup (like updating the dependencies.)  To see how to do that, please check out the steps below.

### Third party tools

We use a few tools to help with development. Running `rake dependencies` will configure or update them for you.

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

You can also open the project by double clicking on `WordPress.xcworkspace` file, or launching Xcode and choose `File` > `Open` and browse to `WordPress.xcworkspace`.

### Setup Credentials

In order to login to WordPress.com with the app you need to create an account over at the [WordPress.com Developer Portal](https://developer.wordpress.com).

After you create an account you can create an application on the [WordPress.com applications manager](https://developer.wordpress.com/apps/).

When creating your application, you should select "Native client" for the application type.
The "**Website URL**", "**Redirect URLs**", and "**Javascript Origins**" fields are required but not used for the mobile apps. Just use `https://localhost`.

Your new application will have an associated client ID and a client secret key. These are used to authenticate the API calls made by your application.

Next, run the command `rake credentials:setup` you will be prompted for your Client ID and your Client Secret.  Once added you will be able to log into the WordPress app

**Remember the only WordPress.com account you will be able to login in with is the one used to create your client ID and client secret.**

Read more about [OAuth2](https://developer.wordpress.com/docs/oauth2/) and the [WordPress.com REST endpoint](https://developer.wordpress.com/docs/api/).

## Contributing

Read our [Contributing Guide](CONTRIBUTING.md) to learn about reporting issues, contributing code, and more ways to contribute.

## Security

If you happen to find a security vulnerability, we would appreciate you letting us know at https://hackerone.com/automattic and allowing us to respond before disclosing the issue publicly.

## Getting in Touch ##

If you have questions about getting setup or just want to say hi, join the [WordPress Slack](https://chat.wordpress.org) and drop a message on the `#mobile` channel.

## Resources

- The [docs](docs/) contain information about our development practices.
- [WordPress Mobile Blog](http://make.wordpress.org/mobile)
- [WordPress Mobile Handbook](http://make.wordpress.org/mobile/handbook/)

## License

WordPress for iOS is an Open Source project covered by the [GNU General Public License version 2](LICENSE).
