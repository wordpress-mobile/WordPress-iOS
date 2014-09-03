<p align="center" >
  <img src="http://inkling.github.io/Subliminal/readme-images/subliminal-hero.png" alt="Subliminal" title="Subliminal">
</p>

[![Build Status](https://travis-ci.org/inkling/Subliminal.svg?branch=master)](https://travis-ci.org/inkling/Subliminal)

Subliminal is a framework for writing iOS integration tests. Subliminal provides 
a familiar OCUnit/XCTest-like interface to Apple's UIAutomation framework, 
with tests written entirely in Objective-C. Subliminal also provides a powerful 
mechanism for your tests to manipulate your application directly.

[
[Features](#features) &bull; 
[Getting Started](#how-to-get-started) &bull; 
[Requirements](#requirements) &bull; 
[Usage](#usage) &bull; 
[Continuous Integration](#continuous-integration) &bull; 
[Contributing](#contributing) &bull; 
[Contact](#contact) &bull; 
[License](#copyright-and-license) 
]

Features
--------

#### Seamless Integration

Write your tests in Objective-C, and run them from Xcode. See rich-text logs 
and screenshots in Instruments. Use UIAutomation to simulate user interaction. 
Subliminal lets you use familiar tools, no dependencies required.

#### Full Control

By using UIAutomation, Subliminal can simulate almost any interaction--without 
resorting to private APIs. From navigating in-app purchase dialogs, to putting 
your app to sleep, Subliminal lets you simulate complex interaction like a user. 
And when you want to manipulate your app directly, Subliminal will help you do 
that too.

#### Scalable Tests

Define Objective-C methods to help set up and tear down tests. Leverage native 
support for continuous integration. Take confidence in Subliminal's complete 
documentation and full test coverage. Subliminal is the perfect foundation 
for your tests.

How to Get Started
------------------

* [Download Subliminal](https://github.com/inkling/Subliminal/zipball/master) 
and [try out the included example app](#running-the-example-app)
* See an [installation walkthrough and screencast](https://github.com/inkling/Subliminal/wiki#installing-subliminal)
* Check out Subliminal's [API documentation](http://inkling.github.io/Subliminal/Documentation/)
or the [guides to using Subliminal on the Wiki](https://github.com/inkling/Subliminal/wiki#documentation)
* Read a [comparison of Subliminal to other integration test frameworks](#comparison-to-other-integration-test-frameworks)

Running the Example App
-----------------------

1. Clone the Subliminal repo: `git clone https://github.com/inkling/Subliminal.git`.
2. `cd` into the directory: `cd Subliminal`.
3. If you haven't already, set up Subliminal: `rake install`.
4. Open the Example project: `open Example/SubliminalTest.xcodeproj`.
5. Switch to the "Integration Tests" scheme.
 You may also see a scheme called "Subliminal Integration tests"--make sure you choose "Integration Tests."
6. Choose Product > Profile (⌘+I).
7. Under the User Templates, choose Subliminal.

Installing Subliminal
---------------------

For an installation walkthrough, refer to [Subliminal's wiki](https://github.com/inkling/Subliminal/wiki).

Requirements
------------

Subliminal supports projects built using Xcode 5.1 and iOS 7.x SDKs,
and deployment targets running iOS 6.1 through 7.1.

For iOS 5.1 support, use Subliminal 1.1.0 (found in the
[Releases](https://github.com/inkling/Subliminal/releases/) section or on
[CocoaPods](http://cocoapods.org/)). To test in the iOS 5.1 Simulator, you will
need to run OS X 10.8 and manually add the iOS 5.1 Simulator to Xcode 5.1,
as described [here](http://stackoverflow.com/a/22494536/495611).

Usage
-----

Subliminal is designed to be instantly familiar to users of OCUnit/XCTest. 
In Subliminal, subclasses of `SLTest` define tests as methods beginning with `test`. 
At run-time, Subliminal discovers and runs these tests. 

Tests manipulate the user interface and can even [manipulate the application directly](https://github.com/inkling/Subliminal/wiki/Writing-Tests#manipulate-the-application-directly).
Here's what a sample test case looks like:

```objc
@implementation STLoginTest

- (void)testLogInSucceedsWithUsernameAndPassword {
	SLTextField *usernameField = [SLTextField elementWithAccessibilityLabel:@"username field"];
	SLTextField *passwordField = [SLTextField elementWithAccessibilityLabel:@"password field" isSecure:YES];
	SLElement *submitButton = [SLElement elementWithAccessibilityLabel:@"Submit"];
	SLElement *loginSpinner = [SLElement elementWithAccessibilityLabel:@"Logging in..."];
	
    NSString *username = @"Jeff", *password = @"foo";
    [usernameField setText:username];
    [passwordField setText:password];

    [submitButton tap];

	// wait for the login spinner to disappear
    SLAssertTrueWithTimeout([loginSpinner isInvalidOrInvisible], 
    						3.0, @"Log-in was not successful.");

    NSString *successMessage = [NSString stringWithFormat:@"Hello, %@!", username];
    SLAssertTrue([[SLElement elementWithAccessibilityLabel:successMessage] isValid], 
    			@"Log-in did not succeed.");
    
    // Check the internal state of the app.			
    SLAssertTrue(SLAskAppYesNo(isUserLoggedIn), @"User is not logged in.")
}

@end
```

For more information, see [Subliminal's wiki](https://github.com/inkling/Subliminal/wiki/Writing-Tests).

Continuous Integration
----------------------

Subliminal includes end-to-end CI support for building your project, running its tests on the appropriate simulator or device, and outputting results in a variety of formats.

For example scripts and guides to integrate with popular CI services like Travis and Jenkins, see [Subliminal's wiki](https://github.com/inkling/Subliminal/wiki/Continuous-Integration).


Comparison to Other Integration Test Frameworks
-----------------------------------------------

* 	**How is Subliminal different from other integration test frameworks?**

	Most other integration test frameworks fall into two categories: entirely 
	Objective-C based, or entirely UIAutomation-based.

	Frameworks that are entirely Objective-C based, like [KIF](https://github.com/square/KIF/), 
	[Frank](https://github.com/moredip/Frank), etc., must hack the application's 
	touch-handling system, using private APIs, to simulate user interaction. 
	There is thus no guarantee that they accurately simulate a user's input. 
	Moreover, these frameworks can only simulate interaction with the application, 
	as opposed to interaction with the device, other processes like in-app purchase 
	alerts, etc.

	Frameworks that are entirely based on Apple's UIAutomation framework require 
	cumbersome workflows--writing tests in JavaScript, in Instruments--which do not 
	make use of the developer's existing toolchain. Moreover, they offer the developer 
	no means of manipulating the application directly--it is a complete black box 
	to a UIAutomation-based test.

	Only Subliminal combines the convenience of writing tests in Objective-C 
	with the power of UIAutomation.

* 	**How is Subliminal different than UIAutomation?**

	Besides the limitations of UIAutomation described above, it is extremely 
	difficult to write UIAutomation tests. This is because UIAutomation requires 
	that user interface elements be identified by their position within the 
	["element hierarchy"](https://developer.apple.com/library/ios/#documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/UsingtheAutomationInstrument/UsingtheAutomationInstrument.html#//apple_ref/doc/uid/TP40004652-CH20-SW88), like

	```js
	var cell = UIATarget.localTarget().frontMostApp().mainWindow().tableViews()[0].cells()["foo"];
	```

	These references are not only difficult to read but are also difficult to write.
	To refer to any particular element, you have to describe its entire ancestry, 
	while including only the views that UIAutomation deems necessary (images, yes; 
	accessible elements, maybe; private `UIWebView` subviews, sure!).

	UIAutomation-based tests are not meant to be written, but to be "recorded" 
	using Instruments. This forces dependence on Instruments, and makes the tests 
	difficult to modify thereafter.

	Subliminal allows developers to identify elements by their properties, 
	independent of their position in the element hierarchy:

    ```objc
    SLElement *fooCell = [SLElement elementWithAccessibilityLabel:@"foo"];
    ```

    Subliminal abstracts away the complexity of UIAutomation scripts to let developers focus on writing tests.

    Subliminal also fixes several bugs in UIAutomation and the `instruments` CLI tool,
    such as `instruments`' lack for [true device support](https://github.com/inkling/Subliminal/pull/75).
    And, last but not least, Subliminal rewrites `instruments`' output using human-friendly formatting
    and ANSI colors:

    ![](http://inkling.github.io/Subliminal/readme-images/PrettyCI.png)


Contributing
------------

Subliminal welcomes pull requests! Check out the [contributing guidelines](https://github.com/inkling/Subliminal/blob/master/CONTRIBUTING.md) to learn how to set up Subliminal for development and how to make a successful pull request.

Credits
-------

Created by [Jeff Wear](https://github.com/wearhere), made possible by [Inkling](https://www.inkling.com/), 
with help from:

* [William Green](http://ca.linkedin.com/pub/william-green/21/724/105)
* [John Detloff](https://github.com/jmdetloff)
* [Aaron Golden](http://stackoverflow.com/users/2172667/aaron-golden)
* [Lukhnos Liu](https://github.com/lukhnos)
* [Aaron Haney](https://github.com/ahaneyinkling)

and Subliminal's [growing list of contributors](https://github.com/inkling/Subliminal/contributors).

Contact
-------

* If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/subliminal). (Tag 'subliminal'.)
* If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/subliminal).
* If you've **found a bug**, [open an issue](https://github.com/inkling/Subliminal/issues/new).
* If you **have a feature request**, [open an issue](https://github.com/inkling/Subliminal/issues/new).
* If you'd **like to contribute** (awesome!), see [the contributing guidelines](https://github.com/inkling/Subliminal/blob/master/CONTRIBUTING.md) to get started.

You can also follow Subliminal ([@subliminaltest](https://twitter.com/subliminaltest))
on Twitter.

Copyright and License
---------------------

Copyright 2013-2014 Inkling Systems, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
