//
//  PostSettingsViewController_Internal.h
//  WordPress
//
//  Created by Eric Johnson on 2/11/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostSettingsViewController.h"

typedef enum {
    PostSettingsSectionTaxonomy = 0,
    PostSettingsSectionMeta,
    PostSettingsSectionFormat,
    PostSettingsSectionFeaturedImage,
    PostSettingsSectionGeolocation
} PostSettingsSection;


@interface PostSettingsViewController ()

@property (nonatomic, strong) NSMutableArray *sections;

@end
