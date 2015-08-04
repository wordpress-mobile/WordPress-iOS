#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Publicize : NSManagedObject

@property (nonatomic, strong) NSString *service;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *connect;

@end
