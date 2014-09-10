//
//  ShareBundleMediaPickerController.h
//
//  Copyright 2013 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>

// Protocol for delegates of the |ShareBundleMediaPickerController| class.
@protocol ShareBundleMediaPickerControllerDelegate

// This delegate method is called if an image is chosen.
- (void)selectedImage:(UIImage *)image;

// This delegate method is called if a video is chosen.
- (void)selectedVideo:(NSURL *)videoURL;

@end

// Table view that allows a user to select a media element from a small list of resources
// bundled with the application.
@interface ShareBundleMediaPickerController : UITableViewController

// Delegate receives a method call when the picker finishes selecting a media element.
@property(nonatomic, weak) id<ShareBundleMediaPickerControllerDelegate> delegate;

@end
