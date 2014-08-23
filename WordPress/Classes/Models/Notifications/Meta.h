#import <CoreData/CoreData.h>
#import <Simperium/SPManagedObject.h>


@interface Meta : SPManagedObject

@property (nonatomic, strong) NSNumber *last_seen;
@property (nonatomic, strong) NSNumber *latest_note_time;

@end
