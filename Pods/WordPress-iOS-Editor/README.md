![WordPress Logo](http://s.w.org/about/images/logos/wordpress-logo-hoz-rgb.png)

# WordPress-iOS-Editor

![WordPress-iOS-Editor Screenshot](https://i.cloudup.com/M_Qk9N3B9k-2000x2000.png)

## Introduction

The WordPress-iOS-Editor is the text editor used in the [WordPress iOS app](https://github.com/wordpress-mobile/WordPress-iOS) to create and edit pages & posts. In short it's a simple, straightforward way to edit raw HTML.

## How to get started
You can install the editor in your app via [CocoaPods](http://cocoapods.org):

```ruby
platform :ios, '7.0'
pod 'WordPress-iOS-Editor'
```

Or, you can just try out the demo by using the Cocoapods try command:

```ruby
pod try WordPress-iOS-Editor
```

## Requirements

WordPress-iOS-Editor requires iOS 7.0 or higher and ARC. It depends on the following Apple frameworks:

* Foundation.framework
* UIKit.framework
* CoreGraphics.framework

and the following Cocoapods:

* [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)
* [UIAlertView+Blocks](https://github.com/jivadevoe/UIAlertView-Blocks)
* [WordPress-iOS-Shared](https://github.com/wordpress-mobile/WordPress-iOS-Shared)

See the [podspec](https://github.com/wordpress-mobile/WordPress-iOS-Editor/blob/develop/WordPress-iOS-Editor.podspec) for more details.

## Usage

There are three things that you need to do in order to use the WordPress-iOS-Editor in your app.

1. Create a ViewController that extends ```WPEditorViewController```

        #import <UIKit/UIKit.h>
        #import <WordPress-iOS-Editor/WPEditorViewController.h>

        @interface WPViewController : WPEditorViewController <WPEditorViewControllerDelegate>

        @end

2. Implement any of the optional ```WPEditorViewControllerDelegate``` [methods](https://github.com/wordpress-mobile/WordPress-iOS-Editor/blob/develop/Classes/WPEditorViewController.h) in your view controller.

3. The ```titleText``` and ```bodyText``` properties can be used to set and get the title and body of the text document.

For more details, you can review the [EditorDemo](https://github.com/wordpress-mobile/WordPress-iOS-Editor/tree/develop/Example) project included in this repo.

## Other Resources

#### Developer blog & Handbook

Blog: http://make.wordpress.org/mobile

Handbook: http://make.wordpress.org/mobile/handbook/

#### Style guide

https://github.com/wordpress-mobile/WordPress-iOS/wiki/WordPress-for-iOS-Style-Guide

#### To report an issue (for the editor only)

https://github.com/wordpress-mobile/WordPress-iOS-Editor/issues

#### Source Code

GitHub: https://github.com/wordpress-mobile/WordPress-iOS-Editor

#### How to Contribute

http://make.wordpress.org/mobile/handbook/pathways/ios/how-to-contribute/

##Future Enhancements

* Replace raw HTML editor with 100% visual editor.

## License

WordPress-iOS-Editor is available under the GPLv2 license. See the [LICENSE](https://raw.githubusercontent.com/wordpress-mobile/WordPress-iOS-Editor/develop/LICENSE) file for more info.
