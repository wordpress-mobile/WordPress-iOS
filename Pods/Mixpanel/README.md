# Using Mixpanel Analytics on iOS #
If you want to track user behavior on your iPhone\iPad application, first
download the Mixpanel iOS API by cloning the git repository:

	git clone http://github.com/mixpanel/mixpanel-iphone.git

Or download [the latest zip
archive](https://github.com/mixpanel/mixpanel-iphone/zipball/master) and
extract the files. The respository has three folders:

1. Mixpanel - The Mixpanel iOS library and its dependencies.
2. HelloMixpanel - A sample application that tracks events and sets user
properties using Mixpanel.
4. Docs - Headerdoc API reference.

# Setup #
Adding Mixpanel to your Xcode project is as easy as:

1. Drag and drop the Mixpanel folder into your project. 
2. Check the "Copy items into destination Group's folder" and select
Recursively create groups for any added folders.

![Copy][copy]

3. Make sure the following Apple frameworks have been added to your project in Targets > Build Phases > Link Binary With Libraries:

- Foundation.framework
- UIKit.framework
- SystemConfiguration.framework
- CoreTelephony.framework

And that's it. 

![Project][project]

# Initializing Mixpanel #
The first thing you need to do is initialize Mixpanel with your project token.
We recommend doing this in `applicationDidFinishLaunching:` or
`application:didFinishLaunchingWithOptions` in your Application delegate. 
	
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    

	    // Override point for customization after application launch.
		[Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];

	    // Add the view controller's view to the window and display.
	    [window addSubview:viewController.view];
	    [window makeKeyAndVisible];
	    return YES;
	}
	
# Tracking Events #
After initializing the Mixpanel object, you are ready to track events. This can
be done with the following code snippet:

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Clicked Button"];
	
If you want to add properties to the event you can do the following:

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Player Create" 
         properties:[NSDictionary dictionaryWithObjectsAndKeys:@"Female", @"Gender", @"Premium", @"Plan", nil]];

# Setting People Properties #
Use the `people` accessor on the Mixpanel object to make calls to the Mixpanel
People API. Unlike Mixpanel Engagement, you must explicitly set the distinct ID
for the current user in Mixpanel People.

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel.people identify:@"user123"];
    [mixpanel.people set:@"Bought Premium Plan" to:[NSDate date]];

To send your users push notifications through Mixpanel People, register device
tokens as follows.

    - (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
        [self.mixpanel.people addPushDeviceToken:devToken];
    }

# ARC #
The Mixpanel library does not currently use ARC. We've chosen to do this
because a large number of customers have not moved to ARC yet. To integrate
with an ARC project: Go to Project > Target > Build Phases, double-click on
each Mixpanel file and add the flag: `-fno-objc-arc`.

# Logging #
You can turn on Mixpanel logging by adding the following Preprocessor Macros in
Build Settings: `MIXPANEL_LOG=1` and `MIXPANEL_DEBUG=1`. Setting
`MIXPANEL_LOG=1` will cause the Mixpanel library to log tracked events and set
People properties. Setting `MIXPANEL_DEBUG=1` will cause Mixpanel to log
everything it's doing—queuing, formatting and uploading data—in a very
fine-grained way, and is useful for understanding how the library works and
debugging issues.

# Further Documentation #
1. [Events iOS Library Documentation](https://mixpanel.com/docs/integration-libraries/iphone)
2. [People iOS Library Documentation](https://mixpanel.com/docs/people-analytics/iphone)
3. [Full Headerdoc API Reference](https://mixpanel.com/site_media/doctyl/uploads/iPhone-spec/Classes/Mixpanel/index.html)

[copy]: https://raw.github.com/mixpanel/mixpanel-iphone/master/Docs/Images/copy.png "Copy"
[project]: https://raw.github.com/mixpanel/mixpanel-iphone/master/Docs/Images/project.png "Project"
