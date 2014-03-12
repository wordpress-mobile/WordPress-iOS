#App passcode library for iOS

<img src ="https://github.com/bakyelli/iOS-PasscodeLock/blob/master/readme_files/background_wallpaper.png?raw=true"/>

A library for iOS developers to protect their apps with a simple 4-digit passcode. 

Works with system notifications to detect app state to present the passcode window to the user.

## Features

 * Uses blocks! 
 * Uses iOS Keychain to store passcode information.
 * Supports activation based on inactivity (in minutes).
 * Lots of styling options. [Screenshot 1][2] [Screenshot 2][3]
 * [Customizable "cover view" to hide the app contents when the app is backgrounded.][1]. 
 * [iPad support][4]

##Installation

For now, add the iOSPasscodeLock folder to your project to start using the library. 

In your AppDelegate `-application:didFinishLaunchingWithOptions:` method, you can activate the protection. 
Make sure to style our Passcode Lock screens to your liking! Call your styling method after activating the library: 

```Objective-C
#import "PasscodeManager.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //...
    
    [[PasscodeManager sharedManager] activatePasscodeProtection];
    [self setPasscodeStyle];
   
    // ...
    return YES;
}

-(void) setPasscodeStyle{

//See the demo project for customization options!

}
```

##Enabling Passcode Protection and Changing Settings

Feel free to design a settings view to toggle passcode protection, changing passcode, and changing inactivity duration. Example can be found in the demo project. [Screenshot][5]

Turning protection on and changing settings are done with simple methods which utilizes blocks! 

Example: 

```Objective-C
[[PasscodeManager sharedManager] setupNewPasscodeWithCompletion:^(BOOL success) {
     if(success){
         //Passcode protection is set-up!
      } else{
        //Passcode protection is NOT set-up!
      }
}];
```

##Notes 

* Even though the iOS Keychain is utilized for storing the Passcode, the `PasscodeProtectionEnabled` property is stored in `NSUserDefaults`. This is to prevent being locked out of the app forever due to the Keychain entries not being removed upon app uninstallation


[1]:https://github.com/bakyelli/iOS-PasscodeLock/blob/master/readme_files/coverview.png?raw=true
[2]:https://github.com/bakyelli/iOS-PasscodeLock/blob/master/readme_files/wp_iphones1.png?raw=true
[3]:https://github.com/bakyelli/iOS-PasscodeLock/blob/master/readme_files/background_wallpaper.png?raw=true
[4]:https://github.com/bakyelli/iOS-PasscodeLock/blob/master/readme_files/wp_ipads.png?raw=true
[5]:https://github.com/bakyelli/iOS-PasscodeLock/blob/master/readme_files/wp_iphones.png?raw=true
