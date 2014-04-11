#import <Foundation/Foundation.h>

@protocol LocalService <NSObject>

@required

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@end
