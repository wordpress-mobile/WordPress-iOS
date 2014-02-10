//
//  Note.m
//  WordPress
//
//  Created by Beau Collins on 11/18/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "Note.h"
#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "ContextManager.h"

const NSUInteger NoteKeepCount = 20;

@interface XMLParserCollecter : NSObject <NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableString *result;
@end
@implementation XMLParserCollecter

- (id)init {
    if (self = [super init]) {
        self.result = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.result appendString:string];
}

@end

@interface Note ()

@property (nonatomic, strong) NSDictionary *noteData;
@property (nonatomic, strong) NSString *commentText;
@property (nonatomic, strong) NSDate *date;

@end

@implementation Note

@dynamic timestamp;
@dynamic type;
@dynamic subject;
@dynamic payload;
@dynamic unread;
@dynamic icon;
@dynamic noteID;
@synthesize commentText = _commentText;
@synthesize noteData = _noteData;
@synthesize date = _date;

+ (void)pruneOldNotesBefore:(NSNumber *)timestamp withContext:(NSManagedObjectContext *)context {
    NSError *error;

    // For some strange reason, core data objects with changes are ignored when using fetchOffset
    // Even if you have 20 notes and fetchOffset is 20, any object with uncommitted changes would show up as a result
    // To avoid that we make sure to commit all changes before doing our request
    [context save:&error];
    NSUInteger keepCount = NoteKeepCount;
    if (timestamp) {
        NSFetchRequest *countRequest = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
        countRequest.predicate = [NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp];
        NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
        countRequest.sortDescriptors = @[ dateSortDescriptor ];
        NSError *error;
        NSUInteger notesCount = [context countForFetchRequest:countRequest error:&error];
        if (notesCount != NSNotFound) {
            keepCount = MAX(keepCount, notesCount);
        }
    }

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.fetchOffset = keepCount;
    NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    request.sortDescriptors = @[ dateSortDescriptor ];
    NSArray *notes = [context executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Error pruning old notes: %@", error);
        return;
    }
    for (Note *note in notes) {
        [context deleteObject:note];
    }
    if(![context save:&error]){
        DDLogError(@"Failed to save after pruning notes: %@", error);
    }
    [context save:&error];
}

+ (NSNumber *)lastNoteTimestampWithContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.resultType = NSDictionaryResultType;
    request.propertiesToFetch = @[@"timestamp"];
    request.fetchLimit = 1;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSArray *results = [context executeFetchRequest:request error:nil];
    NSNumber *timestamp = nil;
    if ([results count]) {
        NSDictionary *note = [results firstObject];
        timestamp = note[@"timestamp"];
    }
    return timestamp;
}

- (void)syncAttributes:(NSDictionary *)noteData {
    self.payload = [NSJSONSerialization dataWithJSONObject:noteData options:0 error:nil];
    self.noteData = [NSJSONSerialization JSONObjectWithData:self.payload options:NSJSONReadingMutableContainers error:nil];
    if ([noteData objectForKey:@"type"]) {
        self.type = [noteData objectForKey:@"type"];
    }
    if ([noteData objectForKey:@"subject"]) {
        NSString *subject = [[noteData objectForKey:@"subject"] objectForKey:@"text"];
        if (!subject)
            subject = [[noteData objectForKey:@"subject"] objectForKey:@"html"];
        self.subject = [subject trim];
        self.icon = [[noteData objectForKey:@"subject"] objectForKey:@"icon"];
    }
    if ([noteData objectForKey:@"timestamp"]) {
        NSInteger timestamp = [[noteData objectForKey:@"timestamp"] integerValue];
        self.timestamp = [NSNumber numberWithInteger:timestamp];
    }
    if ([noteData objectForKey:@"unread"]) {
        NSInteger unread = [[noteData objectForKey:@"unread"] integerValue];
        self.unread = [NSNumber numberWithInteger:unread];
    }
    if ([self isComment] && [noteData objectForKey:@"body"]) {
        [self parseComment];
    }
}

- (BOOL)isComment {
    return [self.type isEqualToString:@"comment"];
}

- (BOOL)isFollow {
    return [self.type isEqualToString:@"follow"];
}

- (BOOL)isLike {
    return [self.type isEqualToString:@"like"];
}

- (BOOL)isUnread {
    return [self.unread boolValue];
}

- (BOOL)isRead {
    return ![self isUnread];
}

- (NSString *)commentText {
    if (_commentText == nil) {
        [self parseComment];
    }
    return _commentText;
}

- (id)noteData {
    if (_noteData == nil) {
        _noteData = [NSJSONSerialization JSONObjectWithData:self.payload options:NSJSONReadingMutableContainers error:nil];
    }
    return _noteData;
}

#pragma mark - Comment HTML parsing

/*
 * Strips HTML Tags and converts html entites
 */
- (void)parseComment {
    
    if ([self isComment]) {
        NSDictionary *bodyItem = [[[self.noteData objectForKey:@"body"] objectForKey:@"items"] lastObject];
        NSString *comment = [bodyItem objectForKey:@"html"];
        if (comment == (id)[NSNull null] || comment.length == 0 )
            return;
        comment = [comment stringByReplacingHTMLEmoticonsWithEmoji];
        comment = [comment stringByStrippingHTML];
        
        NSString *xmlString = [NSString stringWithFormat:@"<d>%@</d>", comment];
        NSData *xml = [xmlString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xml];
        XMLParserCollecter *collector = [[XMLParserCollecter alloc] init];
        parser.delegate = collector;
        [parser parse];
        
        self.commentText = collector.result;
        
    }
    
}


#pragma mark - WPContentViewProvider protocol

- (NSString *)titleForDisplay {
    NSString *title = [self.subject trim];
    if (title.length > 0 && [title hasPrefix:@"["]) {
        // Find location of trailing bracket
        NSRange statusRange = [title rangeOfString:@"]"];
        if (statusRange.location != NSNotFound) {
            title = [title substringFromIndex:statusRange.location + 1];
            title = [title trim];
        }
    }
    title = [title stringByDecodingXMLCharacters];
    return title;
}

- (NSString *)authorForDisplay {
    // Annoyingly, not directly available; could try to parse from self.subject
    return nil;
}

- (NSString *)blogNameForDisplay {
    return nil;
}

- (NSString *)statusForDisplay {
    
    // This is clearly an error prone method of isolating the status,
    // but is necessary due to the current API. This should be changed
    // if/when the API is improved.
    
    NSString *status = [self.subject trim];
    if (status.length > 0 && [status hasPrefix:@"["]) {
        // Find location of trailing bracket
        NSRange statusRange = [status rangeOfString:@"]"];
        if (statusRange.location != NSNotFound) {
            status = [status substringWithRange:NSMakeRange(1, statusRange.location - 1)];
        }
    } else {
        status = nil;
    }
    return status;
}

- (NSString *)contentForDisplay {
    // Contains a lot of cruft
    return self.commentText;
}

- (NSString *)contentPreviewForDisplay {
    return self.commentText;
}

- (NSString *)gravatarEmailForDisplay {
    return nil;
}

- (NSURL *)avatarURLForDisplay {
    return [NSURL URLWithString:self.icon];
}

- (NSDate *)dateForDisplay {
    if (self.date == nil) {
        NSTimeInterval timeInterval = [self.timestamp doubleValue];
        self.date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    
    return self.date;
}

- (BOOL)unreadStatusForDisplay {
    return !self.isRead;
}

@end


#warning TODO: Nuke REST API

@implementation Note (WordPressComApi)

- (void)refreshNoteDataWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    [[[WPAccount defaultWordPressComAccount] restApi] refreshNotifications:@[self.noteID] fields:nil success:^(NSArray *updatedNotes){
            if ([updatedNotes count] > 0 && ![self isDeleted] && self.managedObjectContext) {
                [self syncAttributes:updatedNotes[0]];
            }
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
}

@end
