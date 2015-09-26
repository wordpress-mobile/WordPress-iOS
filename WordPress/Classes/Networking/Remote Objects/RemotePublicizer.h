#import <Foundation/Foundation.h>

@interface RemotePublicizer : NSObject

@property (nonatomic, copy) NSString *service;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *connect;
@property (nonatomic, copy) NSNumber *location;

@end
