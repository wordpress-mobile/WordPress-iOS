#import <Foundation/Foundation.h>

@interface MPSurvey : NSObject

@property (nonatomic, readonly) NSUInteger ID;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly) NSUInteger collectionID;
@property (nonatomic, readonly, strong) NSArray *questions;

+ (MPSurvey *)surveyWithJSONObject:(NSDictionary *)object;

@end
