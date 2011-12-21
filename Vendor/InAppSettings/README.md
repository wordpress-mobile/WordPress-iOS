InAppSettings
========

**InAppSettings** is an open source iPhone and iPod touch framework for displaying an 
in app version of the settings from the *Settings.bundle*. 

![](https://github.com/InScopeApps/InAppSettings/raw/master/Images/InAppSettings.png)

There has been a lot of debate over whether an app's settings should be in the 
app or in the Settings app. **InAppSettings** is an open source framework determined 
to remedy this situation once and for all by easily allowing developers to have 
the same settings in the Settings app in in their app. **InAppSettings** uses the 
same *Settings.bundle* so there is no duplication of files or work. Simply add 
**InAppSettings** to the app's project and call it's view controler from code or 
Interface Builder and you're done! The **InAppSettings** wiki contains a full guide, 
including example code, for adding **InAppSettings** to an iPhone or iPod touch app. 

*By: David Keegan*

With contributions from:

* Shayne Sweeney
* Hendrik Kueck
* Peter Greis
* Kurt Arnlund

Features
--------
* 100% re-implementation of the look and functionality of the Settings app.
* Easily add **InAppSettings** to any navigation controller from code or Interface Builder, **InAppSettings** can also be displayed as a modal view.
* Support for all versions of the iPhone and iPod Touch OS, 2.0+.
* Support for settings language localization.
* **InAppSettings** contains a class method for initializing all the user defaults in the *Settings.bundle*.
* **InAppSettings** adds additional functionality to the *Settings.bundle* by adding optional values for in app titles and opening urls.
* Sample project that demonstrates how to use **InAppSettings** from code, Interface Builder and a modal view.

License
--------
**InAppSettings** was developed by [InScopeApps {+}](http://inscopeapps.com/) and is distributed under the [MIT license](http://www.opensource.org/licenses/mit-license.php) so it can be used in free or comercial apps. See the [LICENSE file](https://github.com/InScopeApps/InAppSettings/blob/master/LICENSE) for more information.

How to add InAppSettings to Your App
========
Drag **InAppSettings** into your project in Xcode. Make sure the dialog looks like this, then press 'Add'.

![](https://github.com/InScopeApps/InAppSettings/raw/master/Images/xcodeadd.png)

If you will be using **InAppSettings** in multiple projects, and I hope you do:), add **InAppSettings** to your *source trees* in the Xcode preferences. If you do this the 'add' settings should look like this, then press 'Add'.

![](https://github.com/InScopeApps/InAppSettings/raw/master/Images/sourcetreeadd.png)

InAppSettingsViewController
--------
The `InAppSettingsViewController` is a subclass of the `UIViewController` that displays the settings from the *Settings.bundle*. It can be used from code and Interface Builder.

**Using InAppSettingsViewController From Code**

    #import "InAppSettings.h"
    
    - (IBAction)showSettings{
        InAppSettingsViewController *settings = [[InAppSettingsViewController alloc] init];
        [self.navigationController pushViewController:settings animated:YES];
        [settings release];
    }

**Using InAppSettingsViewController From Interface Builder**

To use `InAppSettingsViewController` in Interface Builder, change the class type of any `UIViewController` to `InAppSettingsViewController`.

![](https://github.com/InScopeApps/InAppSettings/raw/master/Images/ibadd.png)

To work correctly the `InAppSettingsViewController` must be added to an existing `UINavigationController`.

**InAppSettingsTestApp** demonstrates how to use `InAppSettingsViewController` from code and Interface Builder.

InAppSettingsModalViewController
--------
The `InAppSettingsModalViewController` is a subclass of `UIViewController` that creates its own `UINavigationController`. It is designed to be used as a modal view and is created with a 'Done' button that will dismiss the view.

**How to use InAppSettingsModalViewController from code**

    #import "InAppSettings.h"
    
    - (IBAction)presentSettings{
        InAppSettingsModalViewController *settings = [[InAppSettingsModalViewController alloc] init];
        [self presentModalViewController:settings animated:YES];
        [settings release];
    }

The `InAppSettingsModalViewController` should not be used from Interface Builder.

**InAppSettingsTestApp** demonstrates how to use `InAppSettingsModalViewController` as a modal view.

[InAppSettings registerDefaults]
--------
The user defaults from the *Settings.bundle* are not initialized on startup, and are only initialized when viewed in the Settings App. **InAppSettings** has a registerDefaults class method that can be called to initialize all of the user defaults from the *Settings.bundle*.

**How to use [InAppSettings registerDefaults] from code**

The **InAppSettings** `registerDefaults` method should be called from the AppDelegate's initialize method.

    #import "InAppSettings.h"
    
    + (void)initialize{
        if([self class] == [AppDelegate class]){
            [InAppSettings registerDefaults];
        }
    }

The name of the 'AppDelegate' will need to change to the name of the app's AppDelegate class.

Custom settings specifier keys
========
InAppTitle
--------
`InAppTitle` is an optional settings specifier key that can be added to any settings specifier. If present this title will be used in **InAppSettings**.
    
    <dict>
        <key>Type</key>
        <string>PSGroupSpecifier</string>
        <key>Title</key>
        <string>Change the theme of the app</string>
        <key>InAppTitle</key>
        <string>Change the theme of the app, these changes will take effect the next time the app is launched</string>
    </dict>

The Settings app will display: "Change the theme of the app", but **InAppSettings** will display: "Change the theme of the app, these changes will take effect the next time the app is launched".

InAppURL
--------
`InAppTitle` is an optional settings specifier key that can be added to `PSTitleValueSpecifier`. If present a disclosure indicator will be added to the cell, and the specified url will be opened when the cell is tapped.

    <dict>
        <key>Type</key>
        <string>PSTitleValueSpecifier</string>
        <key>Title</key>
        <string>Created by:</string>
        <key>Key</key>
        <string>testUrl</string>
        <key>DefaultValue</key>
        <string>InScopeApps {+}</string>
        <key>InAppURL</key>
        <string>http://www.inscopeapps.com</string>
    </dict>

To open a webpage the url MUST startwith "http://".

**InAppSettingsTestApp**
--------
The **InAppSettingsTestApp** is a Xcode project for testing **InAppSettings**. It also demonstrates all the ways to use the **InAppSettings** view controllers and class methods.
