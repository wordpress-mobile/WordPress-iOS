#import <Foundation/Foundation.h>

@interface RemoteBlogSettings : NSObject

// General
@property (copy) NSString *name;
@property (copy) NSString *desc;

// Writing
@property (copy) NSNumber *defaultCategory;
@property (copy) NSString *defaultPostFormat;

@end
