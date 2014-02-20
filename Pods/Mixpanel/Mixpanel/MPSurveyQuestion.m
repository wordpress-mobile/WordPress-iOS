#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "MPSurveyQuestion.h"

static NSString *MPSurveyQuestionTypeMultipleChoice = @"multiple_choice";
static NSString *MPSurveyQuestionTypeText = @"text";

@interface MPSurveyQuestion ()

@property (nonatomic) NSUInteger ID;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *prompt;

- (id)initWithID:(NSUInteger)ID type:(NSString *)type andPrompt:(NSString *)prompt;

@end

@interface MPSurveyMultipleChoiceQuestion ()

@property (nonatomic, strong) NSArray *choices;

- (id)initWithID:(NSUInteger)ID type:(NSString *)type prompt:(NSString *)prompt andChoices:(NSArray *)choices;

@end

@implementation MPSurveyQuestion

+ (MPSurveyQuestion *)questionWithJSONObject:(NSDictionary *)object
{
    if (object == nil) {
        NSLog(@"question json object should not be nil");
        return nil;
    }
    NSNumber *ID = object[@"id"];
    if (!([ID isKindOfClass:[NSNumber class]] && [ID integerValue] > 0)) {
        NSLog(@"invalid question id: %@", ID);
        return nil;
    }
    NSString *prompt = object[@"prompt"];
    if (![prompt isKindOfClass:[NSString class]]) {
        NSLog(@"invalid question prompt: %@", prompt);
        return nil;
    }
    NSDictionary *extraData = object[@"extra_data"];
    if (![extraData isKindOfClass:[NSDictionary class]]) {
        NSLog(@"invalid question extra data: %@", extraData);
        return nil;
    }
    NSString *type = object[@"type"];
    if (![type isKindOfClass:[NSString class]]) {
        NSLog(@"invalid question type: %@", type);
        return nil;
    }
    if ([type isEqualToString:MPSurveyQuestionTypeMultipleChoice]) {
        NSArray *choices = extraData[@"$choices"];
        return [[MPSurveyMultipleChoiceQuestion alloc] initWithID:[ID unsignedIntegerValue]
                                                              type:type
                                                            prompt:prompt
                                                        andChoices:choices];
    } else if ([type isEqualToString:MPSurveyQuestionTypeText]) {
        return [[MPSurveyTextQuestion alloc] initWithID:[ID unsignedIntegerValue]
                                                    type:type
                                               andPrompt:prompt];
    }
    NSLog(@"unknown question type: %@", type);
    return nil;
}

- (id)initWithID:(NSUInteger)ID type:(NSString *)type andPrompt:(NSString *)prompt
{
    if (self = [super init]) {
        BOOL valid = NO;
        _ID = ID;
        if ([type isEqualToString:MPSurveyQuestionTypeMultipleChoice] || [type isEqualToString:MPSurveyQuestionTypeText]) {
            self.type = type;
            if (prompt && [prompt length] > 0) {
                self.prompt = prompt;
                valid = YES;
            } else {
                NSLog(@"invalid question type: %@", type);
            }
        } else {
            NSLog(@"invalid question type: %@", type);
        }
        if (!valid) {
            self = nil;
        }
    }
    return self;
}


@end

@implementation MPSurveyMultipleChoiceQuestion

- (id)initWithID:(NSUInteger)ID type:(NSString *)type prompt:(NSString *)prompt andChoices:(NSArray *)choices
{
    if (choices != nil && [choices count] > 0) {
        if (self = [super initWithID:ID type:type andPrompt:prompt]) {
            self.choices = choices;
        }
    } else {
        NSLog(@"invalid choices: %@", choices);
    }
    return self;
}


@end

@implementation MPSurveyTextQuestion

@end
