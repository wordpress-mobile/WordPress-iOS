/*
 * PostSettingsViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "AbstractPost.h"

typedef enum {
    PostSettingsSectionTaxonomy = 0,
    PostSettingsSectionMeta,
    PostSettingsSectionFormat,
    PostSettingsSectionFeaturedImage,
    PostSettingsSectionGeolocation
} PostSettingsSection;

@interface PostSettingsViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) NSString *statsPrefix;

- (id)initWithPost:(AbstractPost *)aPost;
- (void)endEditingAction:(id)sender;

@end
