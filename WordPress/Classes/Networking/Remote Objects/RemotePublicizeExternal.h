#import <Foundation/Foundation.h>

@interface RemotePublicizeExternal : NSObject

@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *picture;
@property (nonatomic, copy) NSNumber *keyring;
@property (nonatomic, copy) NSString *refresh;

- (instancetype)initWithDictionary:(NSDictionary *)remote;

@end
