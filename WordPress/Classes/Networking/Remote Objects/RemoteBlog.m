#import "RemoteBlog.h"
#import "RemoteBlogOptionsHelper.h"

@implementation RemoteBlog

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
{
    if (self = [super init]) {
        _blogID =  [json numberForKey:@"ID"];
        _name = [json stringForKey:@"name"];
        _tagline = [json stringForKey:@"description"];
        _url = [json stringForKey:@"URL"];
        _xmlrpc = [json stringForKeyPath:@"meta.links.xmlrpc"];
        _jetpack = [[json numberForKey:@"jetpack"] boolValue];
        _icon = [json stringForKeyPath:@"icon.img"];
        _capabilities = [json dictionaryForKey:@"capabilities"];
        _isAdmin = [[json numberForKeyPath:@"capabilities.manage_options"] boolValue];
        _visible = [[json numberForKey:@"visible"] boolValue];
        _options = [RemoteBlogOptionsHelper mapOptionsFromResponse:json];
        _planID = [json numberForKeyPath:@"plan.product_id"];
        _planTitle = [json stringForKeyPath:@"plan.product_name_short"];
        _hasPaidPlan = [json stringForKey:@"plan.is_free"] ? ![[json stringForKey:@"plan.is_free"] boolValue] : NO;
    }

    return self;
}

- (NSString *)description
{
    NSDictionary *properties = @{
        @"blogID"    : self.blogID,
        @"name"     : self.name,
        @"url"      : self.url,
        @"xmlrpc"   : self.xmlrpc,
        @"jetpack"  : self.jetpack ? @"YES" : @"NO",
        @"icon"     : self.icon ? self.icon : @"",
        @"visible"  : self.visible ? @"YES" : @"NO",
    };
    
    return [NSString stringWithFormat:@"<%@: %p> (%@)", NSStringFromClass([self class]), self, properties];
}

@end
