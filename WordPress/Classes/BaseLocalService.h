#import <Foundation/Foundation.h>

@protocol BaseLocalService <NSObject>

@required

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@end
