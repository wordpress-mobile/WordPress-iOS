//
//  ShareConfiguration.h
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

#import "DataPickerState.h"

// This class offers a shared instance that maintains the current set of configuration settings
// for sharing to G+.
@interface ShareConfiguration : NSObject

@property(nonatomic, assign) BOOL useNativeSharebox;
// The text to prefill the user comment in the share dialog.
@property(nonatomic, strong) NSString *sharePrefillText;
// The array of people IDs to prefill the share dialog.
@property(nonatomic, strong) NSArray *sharePrefillPeople;
// The URL resource to share in the share dialog.
@property(nonatomic, strong) NSString *shareURL;
// ID for the deep link in the call to action.
@property(nonatomic, strong) NSString *callToActionDeepLinkID;
// URL for the call to action.
@property(nonatomic, strong) NSString *callToActionURL;
// The content deep-link ID to be attached with the Google+ share to qualify as
// a deep-link share.
@property(nonatomic, strong) NSString *contentDeepLinkID;
// The share's title.
@property(nonatomic, strong) NSString *contentDeepLinkTitle;
// The share's description.
@property(nonatomic, strong) NSString *contentDeepLinkDescription;
// The share's thumbnail URL.
@property(nonatomic, strong) NSString *contentDeepLinkThumbnailURL;
// Data picker state to keep track of the call to action label.
@property(nonatomic, strong, readonly) DataPickerState *callToActionLabelState;

// Whether a URL is set to be shared.
@property(nonatomic, assign) BOOL urlEnabled;
// Whether a deep link is set to be shared.
@property(nonatomic, assign) BOOL deepLinkEnabled;
// Whether a call to action is set to be shared.
@property(nonatomic, assign) BOOL callToActionEnabled;
// Whether a media element should be attached.
@property(nonatomic, assign) BOOL mediaAttachmentEnabled;

// Media elements to be attached. Only one will be used; |attachmentImage| has more priority.
@property(nonatomic, strong) UIImage *attachmentImage;
@property(nonatomic, strong) NSURL *attachmentVideoURL;

// Returns shared instance of |ShareConfiguration| class.
+ (ShareConfiguration *)sharedInstance;

// Resets the shared instance of |ShareConfiguration| class.
+ (void)reset;

// Returns dictionary of information describing cell at |indexPath|. The |section| property of
// |indexPath| refers to which type of share option it describes (general share, deep link, or
// call to action). The |row| property indicates which cell in the section is being described.
// |indexPath|'s values are formulated around the ShareConfigurationOptions.plist dictionary.
- (NSDictionary *)cellDataForIndexPath:(NSIndexPath *)indexPath;

// Section accessor methods.
- (NSInteger)numberOfSections;
- (NSInteger)numberOfCellsInSection:(NSInteger)section;
- (NSString *)titleForSection:(NSInteger)section;

// Cell accessor methods.
- (NSString *)labelForCellAtIndexPath:(NSIndexPath *)path;
- (NSString *)typeForCellAtIndexPath:(NSIndexPath *)path;
- (NSString *)propertyForCellAtIndexPath:(NSIndexPath *)path;
- (NSString *)textForCellAtIndexPath:(NSIndexPath *)path;

@end
