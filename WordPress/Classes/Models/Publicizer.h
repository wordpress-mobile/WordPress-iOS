#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Blog.h"


/**
 Encapsulates the available Publicize services for a blog
 */
@interface Publicizer : NSManagedObject

@property (nonatomic, strong) NSString *service;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *connect;
@property (nonatomic, strong) NSNumber *order;
@property (nonatomic, strong) Blog *blog;

/**
 Indicates whether this service is currently connected to its blog
 */
@property (nonatomic, readonly) BOOL isConnected;
/**
 ID of connection, or 0 if none
 */
@property (nonatomic, readonly) NSInteger connectionID;

@end
