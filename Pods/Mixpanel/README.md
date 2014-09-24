[![Build Status](https://travis-ci.org/mixpanel/mixpanel-iphone.svg?branch=yolo-travis-ci)](https://travis-ci.org/mixpanel/mixpanel-iphone)

**Quick start**

1. Install [CocoaPods](http://cocoapods.org/) with `gem install cocoapods`.
2. Create a file in your XCode project called `Podfile` and add the following line:

```ruby
pod 'Mixpanel'
```

3. Run `pod install` in your xcode project directory. CocoaPods should download and
install the Mixpanel library, and create a new Xcode workspace. Open up this workspace in Xcode.
4. Add the following to your `AppDelegate.m`:

```objc
#import <Mixpanel/Mixpanel.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
}
```

5. Start tracking actions in your app:

```objc
[[Mixpanel sharedInstance] track:@"Watched video" properties:@{@"duration": @53}];
```

**Want to Contribute?**

The Mixpanel library for iOS is an open source project, and we'd love to see your contributions! We'd also love for you to come and work with us! Check out http://boards.greenhouse.io/mixpanel/jobs/25226#.U_4JXEhORKU for details.

**Check out the [full documentation »](https://mixpanel.com/help/reference/ios)**
