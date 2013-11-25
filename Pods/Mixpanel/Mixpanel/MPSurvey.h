#import <Foundation/Foundation.h>

@interface MPSurvey : NSObject

@property(nonatomic,readonly) NSUInteger ID;
@property(nonatomic,readonly,retain) NSString *name;
@property(nonatomic,readonly) NSUInteger collectionID;
@property(nonatomic,readonly,retain) NSArray *questions;

+ (MPSurvey *)surveyWithJSONObject:(NSDictionary *)object;

@end
