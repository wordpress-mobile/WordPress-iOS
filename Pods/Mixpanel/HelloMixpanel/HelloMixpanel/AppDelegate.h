//
// AppDelegate.h
// HelloMixpanel
//
// Copyright 2012 Mixpanel
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <UIKit/UIKit.h>

#import "Mixpanel.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, MixpanelDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@property (strong, nonatomic) Mixpanel *mixpanel;

@property (strong, nonatomic, retain) NSDate *startTime;

@property (nonatomic) UIBackgroundTaskIdentifier bgTask;

@end
