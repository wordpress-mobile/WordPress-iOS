
Quantcast iOS SDK
=================

Thank you for downloading the Quantcast iOS SDK! This implementation guide provides steps for integrating the SDK, so you can take advantage of valuable, actionable insights:

* **Know Your Audience** - End the guesswork and limitations of survey-based mobile demographics. Quantcast uses direct measurement and machine learning to build accurate and detailed demographic profiles.
* **Compare and Compete** - Gauge user loyalty by analyzing visit frequency, retention and upgrades over time
* **Showcase and Validate** – Choose to showcase your most powerful data points to advertisers and partners via your public profile. 

If you have any implementation questions, please email mobilesupport@quantcast.com. We're here to help.


Integrating Quantcast Measure for Mobile Apps
---------------------------------------------

### Project Setup ###

To integrate Quantcast’s SDK into your iOS app, you must use Xcode 4.5 or later. Please ensure you are using the latest version of Xcode before you begin the required code integration. The Quantcast SDK fully supports apps built for iOS 5 and later. With some modification, the Quantcast iOS SDK can also support iOS 4.3 and later.

Begin by cloning the Quantcast iOS SDK's git repository and initializing all of its submodules. Open the Terminal application in your Mac and issue the following commands:

``` bash
git clone https://github.com/quantcast/ios-measurement.git ./quantcast-ios-sdk
cd ./quantcast-ios-sdk/
git submodule update --init
```

Once you have downloaded the Quantcast iOS SDK's code, perform the following steps:

1.	Import the code into your project from the Quantcast-iOS-Measurement folder in the Quantcast repository you just created.
2.	Link the following iOS frameworks to your project if they are not already:
	*	`CoreGraphics`
	*	`CoreTelephony`
	*	`Foundation`
	*	`SystemConfiguration`
	*	`UIKit`
3.	Weak-link (that is, make "optional") the following iOS frameworks to your project if they are not already:
	*	`AdSupport`
4.	Link the following libraries to your project, if they aren't already:
	*	`libsqlite3`
	*	`libz`

If you intend to support iOS 4.3 and later, you must perform the following steps:

5.	If you do not have the latest version of JSONKit integrated into your project, import the code from the JSONKit folder in the Quantcast github repository into your project.
6.	Add the following preprocessor macro definition to your project's precompiled header file (the file that ends with '.pch'):

	```objective-c
	#define QCMEASUREMENT_ENABLE_JSONKIT 1
	```

### SDK Integration ###
There are two ways to integrate the Quantcast SDK. The first is a [One Step Integration](#one-step-sdk-integration) which allows you to integrate the Quantcast SDK with a single line of code. Most integrations should use this method. However, if you need want more control over how the Quantcast SDK logs your apps pause and resume events, then you should use the [Detailed SDK Integration](#detailed-sdk-integration) which can be accomplished with four lines of code. You would use the Detailed SDK Integration if you need to pass updated or different labels when the app pauses or resumes.

#### One Step SDK Integration ####

One Step Integration can be used for simpler implementations of the Quantcast SDK.  Projects that use constant or no [Event Labels](#event-labels) will benefit the most.   This method automatically sets up the pause/resume/end methods for you so this will be the only call you need to make to accomplish the minimum integration. If you use this integration method, you are still free to utilize the optional features, such as [Tracking App Events](#tracking-app-events).  

In order integration using One Step Integration:

1.	Import `QuantcastMeasurement.h` into your `UIApplication` delegate class
2.	In your `UIApplication` delegate's `application:didFinishLaunchingWithOptions:` method, place the following:

	```objective-c
	[[QuantcastMeasurement sharedInstance] setupMeasurementSessionWithAPIKey:@"<*Insert your API Key Here*>" userIdentifier:userIdentifierStrOrNil labels:nil];
    ```

	Replace "<\*Insert your API Key Here\*>" with your Quantcast API Key, which can be generated in your Quantcast account homepage on [the Quantcast website](http://www.quantcast.com "Quantcast.com"). The API Key is used as the basic reporting entity for Quantcast Measure. The same API Key can be used across multiple apps (i.e. AppName Free / AppName Paid) and/or app platforms (i.e. iOS / Android). For all apps under each unique API Key, Quantcast will report the aggregate audience among them all, and also identify/report on the individual app versions.

	The `userIdentifier:` parameter is a string that uniquely identifies an individual user, such as an account login.  This is not to be confused with a unique device identifier. Passing this information allows Quantcast to provide reports on your combined audience across all your properties: online, mobile web and mobile app. This parameter may be nil if your app does not have a user identifier available at the time your app launches. If the user identifier is not known at the time `setupMeasurementSessionWithAPIKey:userIdentifier:labels:` is called, the user identifier can be recorded at a later time. Please see the [Combined Web/App Audiences](#combined-webapp-audiences) section for more information.

	The `labels:` parameter may be nil and is discussed in more detail in the [Event Labels](#event-labels) section under Optional Code Integrations.

By using the `setupMeasurementSessionWithAPIKey:userIdentifier:labels:` call, it is not necessary to add the `beginMeasurementSessionWithAPIKey:userIdentifier:labels:`, `pauseSessionWithLabels:`, or `resumeSessionWithLabels:` calls to the code. You may optionally call `endMeasurementSessionWithLabels:` at any time to explicitly end the measurement session, but this is not required.

#### Detailed SDK Integration ####

For those application wishing to utilize more control over audience segmentation and labeling then the Quantcast iOS SDK has four points of required code integration. If you utilize the Detailed SDK Integration method, then the `setupMeasurementSessionWithAPIKey:userIdentifier:labels:` should not be called.  The four points of integration is a set of required calls to the SDK to indicate when the iOS app has been launched, paused (put into the background), resumed, and quit. 

To implement the required set of SDK calls, perform the following steps:

1.	Import `QuantcastMeasurement.h` into your `UIApplication` delegate class
2.	In your `UIApplication` delegate's `application:didFinishLaunchingWithOptions:` method, place the following:

	```objective-c
	[[QuantcastMeasurement sharedInstance] beginMeasurementSessionWithAPIKey:@"<*Insert your API Key Here*>" userIdentifier:userIdentifierStrOrNil labels:nil];
	```
		
	Replace "<\*Insert your API Key Here\*>" with your Quantcast API Key, which can be generated in your Quantcast account homepage on [the Quantcast website](http://www.quantcast.com "Quantcast.com"). The API Key is used as the basic reporting entity for Quantcast Measure. The same API Key can be used across multiple apps (i.e. AppName Free / AppName Paid) and/or app platforms (i.e. iOS / Android). For all apps under each unique API Key, Quantcast will report the aggregate audience among them all, and also identify/report on the individual app versions.

	The `userIdentifier:` parameter is a string that uniquely identifies an individual user, such as an account login.  This is not to be confused with a unique device identifier. Passing this information allows Quantcast to provide reports on your combined audience across all your properties: online, mobile web and mobile app. This parameter may be nil if your app does not have a user identifier available at the time your app launches. If the user identifier is not known at the time the `application:didFinishLaunchingWithOptions:` method is called, the user identifier can be recorded at a later time. Please see the [Combined Web/App Audiences](#combined-webapp-audiences) section for more information.
	
	The labels parameter may be nil and is discussed in more detail in the [Event Labels](#event-labels) section under Optional Code Integrations.
	
3.	In your `UIApplication` delegate's `applicationWillTerminate:` method, place the following:

	```objective-c
	[[QuantcastMeasurement sharedInstance] endMeasurementSessionWithLabels:nil];
	```
		
4.	In your `UIApplication` delegate's `applicationDidEnterBackground:` method, place the following:

	```objective-c
	[[QuantcastMeasurement sharedInstance] pauseSessionWithLabels:nil];
	```

5.	In your `UIApplication` delegate's `applicationWillEnterForeground:` method, place the following:

	```objective-c
	[[QuantcastMeasurement sharedInstance] resumeSessionWithLabels:nil];
	```

### User Privacy ###

#### Privacy Notification ####
Quantcast believes in informing users of how their data is being used.  We recommend that you disclose in your privacy policy that you use Quantcast to understand your audiences. You may link to Quantcast's privacy policy [here](https://www.quantcast.com/privacy).

#### User Opt-Out ####
You can give users the option to opt out of Quantcast Measure by providing access to the Quantcast Measure Opt-Out dialog. This should be accomplished with a button or a table view cell (if your options are based on a grouped table view) in your app's options view with the title "Measurement Options" or "Privacy". When a user taps the button you provide, call the Quantcast’s Opt-Out dialog using the following method:

```objective-c
[[QuantcastMeasurement sharedInstance] displayUserPrivacyDialogOver:currentViewController withDelegate:nil];
```
		
The `currentViewController` argument is the current view controller. The SDK needs to know this due to how the iOS SDK presents modal dialogs (see [Apple's documentation](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIViewController_Class/Reference/Reference.html) for `presentViewController:animated:completion:`). The delegate is an optional parameter and is explained in the `QuantcastOptOutDelegate` protocol header.
	
Note: when a user opts out of Quantcast Measure, the SDK immediately stops transmitting information to or from the user's device and deletes any cached information that may have retained. Furthermore, when a user opts out of any single app on a device, the action affects all other apps on the device that are integrated with Quantcast Measure the next time they are launched.

### Optional Code Integrations ###

#### Tracking App Events ####
Quantcast Measure can be used to measure audiences that engage in certain activities within your app. To log the occurrence of an app event or activity, call the following method:

```objective-c
[[QuantcastMeasurement sharedInstance] logEvent:theEventStr withLabels:nil];
```
`theEventStr` is the string that is associated with the event you are logging. Hierarchical information can be indicated by using a left-to-right notation with a period as a separator. For example, logging one event named "button.left" and another named "button.right" will create three reportable items in Quantcast Measure: "button.left", "button.right", and "button". There is no limit on the cardinality that this hierarchal scheme can create, though low-frequency events may not have an audience report due to the lack of a statistically significant population.

#### Event Labels ####
Most of Quantcast SDK's public methods have an option to provide one or more labels, or `nil` if no label is desired. A label is any arbitrary string that you want associated with an event. The label will create a second dimension in Quantcast Measure audience reporting. Normally, this dimension is a "user class" indicator. For example, you could use one of two labels in your app: one for users who have not purchased an app upgrade, and one for users who have purchased an upgrade.

The `labels:` argument of most Quantcast SDK methods is typed to be an `id` pointer. However, it only accepts either a `NSString` object representing a single label, or a `NSArray` object containing one or more `NSString` objects representing a collection of labels to be applied to the event.

Labels can also be set via the appLabels property.   These labels can be changed at any time and will be automatically combined with the labels passed in any call taking labels.  This can be convenient for those apps who find themselves passing the same labels everywhere. 

While there is no specific constraint on the intended use of the label dimension, it is not recommended that you use it to indicate discrete events; in these cases, use the `logEvent:withLabels:` method described under [Tracking App Events](#tracking-app-events).

#### Geo-Location Measurement ####
To turn on geo-location measurement, please take the following steps:

1. Link your project to the `CoreLocation` framework
2. Ensure that the `QuantcastGeoManager.m` compile unit , which can be found in the `Optional` folder of the SDK, has been added to your project.
3. Add the following line to your project's pre-compiled header file:
   
   ```objective-c
   #define QCMEASUREMENT_ENABLE_GEOMEASUREMENT 1
   ```

4. Insert the following call into your `UIApplication` delegate's `application:didFinishLaunchingWithOptions:` method after you call either form of the `beginMeasurementSession:` methods:

   ```objective-c
   [QuantcastMeasurement sharedInstance].geoLocationEnabled = YES;
   ```

You may also safely change the state of the `geoLocationEnabled` at any point after your app has launched. The Quantcast SDK will always adhere to its current setting.

Note that you should only enable geo-tracking if your app has some location-aware purpose for the user.

The Quantcast iOS SDK will automatically pause geo-tracking while your app is in the background. This is done for both battery life and privacy considerations.

#### Digital Magazines and Periodicals ####
Quantcast Measure provides measurement features specific to digital magazines and periodicals. These options allow the measurement of specific issues, articles and pages in addition to the general measurement of the app hosting the magazine. In order to take advantage of this measurement, you must at a minimum tag when a particular issue has been opened and closed and when each page in that issue has been viewed (in addition to the basic SDK integration). You may also optionally tag when a particular article has been viewed. For more information, please refer to the documentation in the Periodicals header file which can be found in the SDK source folder at `Optional/QuantcastMeasurement+Periodicals.h`.  

#### Combined Web/App Audiences ####
Quantcast Measure enables you to measure your combined web and mobile app audiences, allowing you to understand the differences and similarities of your online and mobile app audiences, or even the combined audiences of your different apps. To enable this feature, you will need to provide a user identifier, which Quantcast will always anonymize with a 1-way hash before it is transmitted from the user's device. This user identifier should also be provided for your website(s); please see [Quantcast's web measurement documentation](https://www.quantcast.com/learning-center/guides/cross-platform-audience-measurement-guide) for instructions.

Normally, your app user identifier would be provided in your `UIApplication` delegate's `application:didFinishLaunchingWithOptions:` method via the `beginMeasurementSessionWithAPIKey:userIdentifier:labels:` method as described in the [Required Code Integration](#required-code-integration) section above. If the app's active user identifier changes later in the app's life cycle, you can update the user identifier using the following method call:

```objective-c
[[QuantcastMeasurement sharedInstance] recordUserIdentifier:userIdentifierStr withLabels:nil];
```
The current user identifier is passed in the `userIdentifierStr` argument. 

Note that in all cases, the Quantcast iOS SDK will immediately 1-way hash the passed app user identifier, and return the hashed value for your reference. You do not need to take any action with the hashed value.

#### SDK Customization ####

##### Logging and Debugging #####
You may enable logging within the Quantcast iOS SDK for debugging purposes. By default, logging is turned off. To enable logging, call the following method at any time, including prior to calling either of the `beginMeasurementSession:` methods:

```objective-c
[QuantcastMeasurement sharedInstance].enableLogging = YES;
```
You should not release an app with logging enabled.

##### Event Upload Frequency #####
The Quantcast iOS SDK will upload the events it collects to Quantcast's server periodically. Uploads that occur too often will drain the device's battery. Uploads that don't occur often enough will cause significant delays in Quantcast receiving the data needed for analysis and reporting. By default, these uploads occur when at least 100 events have been collected or when your application pauses (that is, it switched into the background). You can alter this default behavior by setting the `uploadEventCount` property. For example, if you wish to upload your app's events after 20 events have been collected, you would make the following call:

```objective-c
[QuantcastMeasurement sharedInstance].uploadEventCount = 20;
```

You may change this property multiple times throughout your app's execution.

##### Secure Data Uploads #####
The Quantcast iOS SDK can support secure data uploads using SSL/TLS. In order to enable secure data uploads, first link your project to the `Security` framework. Then add following preprocessor macro definition to your project's precompiled header file (the file that ends with '.pch'):

```objective-c
#define QCMEASUREMENT_USE_SECURE_CONNECTIONS 1
```

Note that using secure data uploads causes your app to use encryption technology. Various jurisdictions have laws controlling the export of software applications that use encryption. Please review your jurisdiction's laws concerning exporting software that uses encryption before enabling secure data uploads in the Quantcast iOS SDK. 

### Trouble Shooting ###

**Little or No App Traffic Showing Up In App's Profile On Quantcast.com**<br>
Quantcast updates its website with your app's latest audience measurement data daily. If even after 1 day no data is showing up in your app's profile on quantcast.com, there are several things to check:
* If you are using the [Detailed SDK Integration](#detailed-sdk-integration) method to integrate, please ensure that you have fully integrated as described above.
* Check to ensure that your app does not have the `UIApplicationExitsOnSuspend` property set to `YES` in your app's `Info.plist`. For the Quantcast iOS SDK to function correctly, the `UIApplicationExitsOnSuspend` property should be removed from your app's `Info.plist`.
* The Quantcast SDK does most of its data uploading when your app is transitioned to the background. If during your development and testing workflow in Xcode you regularly end a test run of your app by pressing "stop" within Xcode, your app has not necessarily had a chance to upload usage data. To ensure your app gets a chance to upload usage data to Quantcast while you are testing, be sure to click the Home button on the device being tested in order to put your app into the background and thus trigger a usage data upload to Quantcast.



## License ##
This Quantcast Measurement SDK is Copyright 2012 Quantcast Corp. This SDK is licensed under the Quantcast Mobile App Measurement Terms of Service, found at [the Quantcast website here](https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos "Quantcast's Measurement SDK Terms of Service") (the "License"). You may not use this SDK unless (1) you sign up for an account at [Quantcast.com](https://www.quantcast.com "Quantcast.com") and click your agreement to the License and (2) are in compliance with the License. See the License for the specific language governing permissions and limitations under the License.