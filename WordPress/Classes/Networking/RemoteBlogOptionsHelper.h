#import <Foundation/Foundation.h>

@class RemoteBlogSettings;

@interface RemoteBlogOptionsHelper : NSObject

+ (NSDictionary *)mapOptionsFromResponse:(NSDictionary *)response;

// Helper methods for converting between XMLRPC dictionaries and RemoteBlogSettings
// Currently, we are only ever updating the blog title or tagline through XMLRPC
// Brent - Jan 7, 2017
+ (NSDictionary *)remoteOptionsForUpdatingBlogTitleAndTagline:(RemoteBlogSettings *)blogSettings;
+ (RemoteBlogSettings *)remoteBlogSettingsFromXMLRPCDictionaryOptions:(NSDictionary *)json;

@end
