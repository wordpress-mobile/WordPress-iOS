#import <Foundation/Foundation.h>

@interface RemotePublicizeExternal : NSObject

@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *picture;

- (instancetype)initWithDictionary:(NSDictionary *)remote;

@end
