#import <Foundation/Foundation.h>

@protocol LocalCoreDataService <NSObject>

@required

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@end
