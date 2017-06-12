#import "RemoteBlogOptionsHelper.h"
#import "NSMutableDictionary+Helpers.h"
#import <WordPressKit/WordPressKit-Swift.h>
@import NSObject_SafeExpectations;
@import WordPressShared;

@implementation RemoteBlogOptionsHelper

// Formats blog options retrieved from REST queries
+ (NSDictionary *)mapOptionsFromResponse:(NSDictionary *)response
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[@"home_url"] = response[@"URL"];
    if ([[response numberForKey:@"jetpack"] boolValue]) {
        options[@"jetpack_client_id"] = [response numberForKey:@"ID"];
    }
    if ( response[@"options"] ) {
        options[@"post_thumbnail"] = [response valueForKeyPath:@"options.featured_images_enabled"];
        NSArray *optionsDirectMapKeys = @[
                                          @"active_modules",
                                          @"admin_url",
                                          @"login_url",
                                          @"image_default_link_type",
                                          @"software_version",
                                          @"videopress_enabled",
                                          @"timezone",
                                          @"gmt_offset",
                                          @"allowed_file_types",
                                          @"frame_nonce",
                                          @"blog_public"
                                          ];

        for (NSString *key in optionsDirectMapKeys) {
            NSString *sourceKeyPath = [NSString stringWithFormat:@"options.%@", key];
            if ([response valueForKeyPath:sourceKeyPath] != nil) {
                options[key] = [response valueForKeyPath:sourceKeyPath];
            }
        }
    }
    NSMutableDictionary *valueOptions = [NSMutableDictionary dictionaryWithCapacity:options.count];
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        valueOptions[key] = @{@"value": obj};
    }];

    return [NSDictionary dictionaryWithDictionary:valueOptions ];
}

+ (NSDictionary *)remoteOptionsForUpdatingBlogTitleAndTagline:(RemoteBlogSettings *)blogSettings
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setValueIfNotNil:blogSettings.name forKey:@"blog_title"];
    [options setValueIfNotNil:blogSettings.tagline forKey:@"blog_tagline"];
    return options;
}

+ (RemoteBlogSettings *)remoteBlogSettingsFromXMLRPCDictionaryOptions:(NSDictionary *)options
{
    RemoteBlogSettings *remoteSettings = [RemoteBlogSettings new];
    remoteSettings.name = [[options stringForKeyPath:@"blog_title.value"] stringByDecodingXMLCharacters];
    remoteSettings.tagline = [[options stringForKeyPath:@"blog_tagline.value"] stringByDecodingXMLCharacters];
    if (options[@"blog_public"]) {
        remoteSettings.privacy = [options numberForKeyPath:@"blog_public.value"];
    }
    return remoteSettings;
}

@end
