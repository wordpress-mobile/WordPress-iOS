#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "MPSurvey.h"
#import "MPSurveyQuestion.h"

@interface MPSurvey ()

@property (nonatomic) NSUInteger ID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) NSUInteger collectionID;
@property (nonatomic, strong) NSArray *questions;

- (id)initWithID:(NSUInteger)ID name:(NSString *)name collectionID:(NSUInteger)collectionID andQuestions:(NSArray *)questions;

@end

@implementation MPSurvey

+ (MPSurvey *)surveyWithJSONObject:(NSDictionary *)object
{
    if (object == nil) {
        NSLog(@"survey json object should not be nil");
        return nil;
    }
    NSNumber *ID = object[@"id"];
    if (!([ID isKindOfClass:[NSNumber class]] && [ID integerValue] > 0)) {
        NSLog(@"invalid survey id: %@", ID);
        return nil;
    }
    NSString *name = object[@"name"];
    if (![name isKindOfClass:[NSString class]]) {
        NSLog(@"invalid survey name: %@", name);
        return nil;
    }
    NSArray *collections = object[@"collections"];
    if (!([collections isKindOfClass:[NSArray class]] && [collections count] > 0)) {
        NSLog(@"invalid survey collections: %@", collections);
        return nil;
    }
    NSDictionary *collection = collections[0];
    if (![collection isKindOfClass:[NSDictionary class]]) {
        NSLog(@"invalid survey collection: %@", collection);
        return nil;
    }
    NSNumber *collectionID = collection[@"id"];
    if (!([collectionID isKindOfClass:[NSNumber class]] && [collectionID integerValue] > 0)) {
        NSLog(@"invalid survey collection id: %@", collectionID);
        return nil;
    }
    NSMutableArray *questions = [NSMutableArray array];
    for (NSDictionary *question in object[@"questions"]) {
        MPSurveyQuestion *q = [MPSurveyQuestion questionWithJSONObject:question];
        if (q) {
            [questions addObject:q];
        }
    }
    return [[MPSurvey alloc] initWithID:[ID unsignedIntegerValue]
                                    name:name
                            collectionID:[collectionID unsignedIntegerValue]
                            andQuestions:[NSArray arrayWithArray:questions]];
}

- (id)initWithID:(NSUInteger)ID name:(NSString *)name collectionID:(NSUInteger)collectionID andQuestions:(NSArray *)questions
{
    if (self = [super init]) {
        BOOL valid = YES;
        if (!(name && name.length > 0)) {
            valid = NO;
            NSLog(@"Invalid survey name %@", name);
        }
        if (!(questions && [questions count] > 0)) {
            valid = NO;
            NSLog(@"Survey must have at least one question %@", questions);
        }

        if (valid) {
            _ID = ID;
            self.name = name;
            _collectionID = collectionID;
            self.questions = questions;
        } else {
            self = nil;
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, (ID:%lu, collection:%lu questions:%lu)", self.name, (unsigned long)self.ID, (unsigned long)self.collectionID, (unsigned long)[self.questions count]];
}


@end
