#import <Foundation/Foundation.h>

@interface MPSurveyQuestion : NSObject

@property(nonatomic,readonly) NSUInteger ID;
@property(nonatomic,readonly,retain) NSString *type;
@property(nonatomic,readonly,retain) NSString *prompt;

+ (MPSurveyQuestion *)questionWithJSONObject:(NSObject *)object;

@end

@interface MPSurveyMultipleChoiceQuestion : MPSurveyQuestion

@property(nonatomic,readonly,retain) NSArray *choices;

@end

@interface MPSurveyTextQuestion : MPSurveyQuestion

@end
