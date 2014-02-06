## Version 3.5.0

- [Changelog](http://www.hockeyapp.net/help/sdk/ios/3.5.0/docs/docs/Changelog.html)

## Introduction

This article describes how to integrate HockeyApp into your iOS apps using a Git submodule and Xcode sub-projects. The SDK allows testers to update your app to another beta version right from within the application. It will notify the tester if a new update is available. The SDK also allows to send crash reports. If a crash has happened, it will ask the tester on the next start whether he wants to send information about the crash to the server.

This document contains the following sections:

- [Requirements](#requirements)
- [Set up Git submodule](#download)
- [Set up Xcode](#xcode)
- [Modify Code](#modify)
- [Additional Options](#options)

<a id="requirements"></a> 
## Requirements

The SDK runs on devices with iOS 5.0 or higher.

<a id="download"></a> 
## Set up Git submodule

1. Open a Terminal window

2. Change to your projects directory `cd /path/to/MyProject'

3. If this is a new project, initialize Git: `git init`

4. Add the submodule: `git submodule add git://github.com/bitstadium/HockeySDK-iOS.git Vendor/HockeySDK`. This would add the submodule into the `Vendor/HockeySDK` subfolder. Change this to the folder you prefer.

5. Releases are always in the `master` branch while the `develop` branch provides the latest in development source code (Using the git flow branching concept). We recommend using the `master` branch!

<a id="xcode"></a> 
## Set up Xcode

1. Find the `HockeySDK.xcodeproj` file inside of the cloned HockeySDK-iOS project directory.

2. Drag & Drop it into the `Project Navigator` (⌘+1).

3. Select your project in the `Project Navigator` (⌘+1).

4. Select your app target. 

5. Select the tab `Build Phases`.

6. Expand `Link Binary With Libraries`.

7. Add `libHockeySDK.a`

    <img src="XcodeLinkBinariesLib_normal.png"/>

8. Select `Add Other...`.

9. Select `CrashReporter.framework` from the `Vendor/HockeySDK/Vendor` folder

    <img src="XcodeFrameworks4_normal.png"/>

10. Add the following system frameworks, if they are missing:
    - `CoreText`
    - `CoreGraphics`
    - `Foundation`
    - `QuartzCore`
    - `Security`
    - `SystemConfiguration`
    - `UIKit`

11. Expand `Copy Bundle Resource`.

12. Drag `HockeySDKResources.bundle` from the `HockeySDK` sub-projects `Products` folder and drop into the `Copy Bundle Resource` section

13. Select `Build Settings`

14. Add the following `Header Search Path`

    `$(SRCROOT)/Vendor/HockeySDK/Classes`

<a id="modify"></a> 
## Modify Code

1. Open your `AppDelegate.m` file.

2. Add the following line at the top of the file below your own #import statements:

        #import "HockeySDK.h"

3. Let the AppDelegate implement the protocols `BITHockeyManagerDelegate`:

   <pre><code>@interface AppDelegate(HockeyProtocols) < BITHockeyManagerDelegate > {}
   @end</code></pre>

4. Search for the method `application:didFinishLaunchingWithOptions:`

5. Add the following lines:

        [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:@"BETA_IDENTIFIER"
                                                             liveIdentifier:@"LIVE_IDENTIFIER"
                                                                   delegate:self];
        [[BITHockeyManager sharedHockeyManager] startManager];

6. Replace `BETA_IDENTIFIER` with the app identifier of your beta app. If you don't know what the app identifier is or how to find it, please read [this how-to](http://support.hockeyapp.net/kb/how-tos/how-to-find-the-app-identifier). 

7. Replace `LIVE_IDENTIFIER` with the app identifier of your release app. We suggest to setup different apps on HockeyApp for your test and production builds. You usually will have way more test versions, but your production version usually has way more crash reports. This helps to keep data separated, getting a better overview and less trouble setting the right app versions downloadable for your beta users.

8. If you want to use the beta distribution feature on iOS 7 or later with In-App Updates, restrict versions to specific users or want to know who is actually testing your app, you need to follow the instructions on our guide [Identify and authenticate users of Ad-Hoc or Enterprise builds](HowTo-Authenticating-Users-on-iOS)

*Note:* The SDK is optimized to defer everything possible to a later time while making sure e.g. crashes on startup can also be caught and each module executes other code with a delay some seconds. This ensures that applicationDidFinishLaunching will process as fast as possible and the SDK will not block the startup sequence resulting in a possible kill by the watchdog process.

<a id="options"></a> 
## Additional Options

### Mac Desktop Uploader

The Mac Desktop Uploader can provide easy uploading of your app versions to HockeyApp. Check out the [installation tutorial](Guide-Installation-Mac-App).

### Xcode Documentation

This documentation provides integrated help in Xcode for all public APIs and a set of additional tutorials and HowTos.

1. Download the [HockeySDK-iOS documentation](http://hockeyapp.net/releases/).

2. Unzip the file. A new folder `HockeySDK-iOS-documentation` is created.

3. Copy the content into ~`/Library/Developer/Shared/Documentation/DocSet`

The documentation is also available via the following URL: [http://hockeyapp.net/help/sdk/ios/3.5.0/](http://hockeyapp.net/help/sdk/ios/3.5.0/)

### Set up with xcconfig

Instead of manually adding the missing frameworks, you can also use our bundled xcconfig file.

1. Create a new `Project.xcconfig` file, if you don't already have one (You can give it any name)
 
    **Note:** You can also add the required frameworks manually to your targets `Build Phases` an continue with step `4.` instead.
 
    a. Select your project in the `Project Navigator` (⌘+1).
 
    b. Select the tab `Info`.
 
    c. Expand `Configurations`.
 
    d. Select `Project.xcconfig` for all your configurations
    
        <img src="XcodeFrameworks1_normal.png"/>
 
2. Open `Project.xcconfig` in the editor
 
3. Add the following line:
 
    `#include "../Vendor/HockeySDK/Support/HockeySDK.xcconfig"`
    
    (Adjust the path depending where the `Project.xcconfig` file is located related to the Xcode project package)
    
    **Important note:** Check if you overwrite any of the build settings and add a missing `$(inherited)` entry on the projects build settings level, so the `HockeySDK.xcconfig` settings will be passed through successfully.
    
4. If you are getting build warnings, then the `.xcconfig` setting wasn't included successfully or its settings in `Other Linker Flags` get ignored because `$(inherited)` is missing on project or target level. Either add `$(inherited)` or link the following frameworks manually in `Link Binary With Libraries` under `Build Phases`:
    - `CoreText`
    - `CoreGraphics`
    - `Foundation`
    - `QuartzCore`
    - `Security`
    - `SystemConfiguration`
    - `UIKit`
