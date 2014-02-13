//
//  Note.m
//  WordPress
//
//  Created by Beau Collins on 11/18/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "Note.h"
#import "NSString+Helpers.h"
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
@property (nonatomic, strong, readwrite) NSDictionary *noteData;
@property (readwrite, nonatomic, strong) NSString *commentText;

@end

@implementation Note

@dynamic timestamp;
@dynamic type;
@dynamic subject;
@dynamic payload;
@dynamic unread;
@dynamic icon;
@dynamic noteID;
@dynamic account;
@synthesize commentText = _commentText, noteData = _noteData;


+ (void)syncNotesWithResponse:(NSArray *)notesData {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] backgroundContext];
    [context performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
        NSError *error;
        NSArray *existingNotes = [context executeFetchRequest:request error:&error];
        if (error){
            DDLogError(@"Error finding notes: %@", error);
            return;
        }
        
        WPAccount *account = (WPAccount *)[context objectWithID:[WPAccount defaultWordPressComAccount].objectID];
        [notesData enumerateObjectsUsingBlock:^(NSDictionary *noteData, NSUInteger idx, BOOL *stop) {
            NSNumber *noteID = [noteData objectForKey:@"id"];
            NSArray *results = [existingNotes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"noteID == %@", noteID]];
            
            Note *note;
            if ([results count] != 0) {
                note = results[0];
            } else {
                note = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self) inManagedObjectContext:context];
                note.noteID = [noteData objectForKey:@"id"];
                note.account = account;
            }
            [note syncAttributes:noteData];
        }];
        
        [[ContextManager sharedInstance] saveContext:context];
    }];
}

+ (void)refreshUnreadNotesWithContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[ContextManager sharedInstance].managedObjectModel fetchRequestTemplateForName:@"UnreadNotes"];
    NSError *error = nil;
    NSArray *notes = [context executeFetchRequest:request error:&error];
    if ([notes count] > 0) {
        [[WordPressComApi sharedApi] refreshNotifications:notes fields:@"id,unread" success:nil failure:nil];
    }
}

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

+ (void)getNewNotificationswithContext:(NSManagedObjectContext *)context success:(void (^)(BOOL hasNewNotes))success failure:(void (^)(NSError *error))failure {
    NSNumber *timestamp = [self lastNoteTimestampWithContext:context];

    [[WordPressComApi sharedApi] getNotificationsSince:timestamp success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *notes = [responseObject arrayForKey:@"notes"];
        if (success) {
            success([notes count] > 0);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

+ (NSNumber *)lastNoteTimestampWithContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.resultType = NSDictionaryResultType;
    request.propertiesToFetch = @[@"timestamp"];
    request.fetchLimit = 1;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSArray *results = [context executeFetchRequest:request error:nil];
    NSNumber *timestamp;
    if ([results count]) {
        NSDictionary *note = results[0];
        timestamp = [note objectForKey:@"timestamp"];
    }
    return timestamp;
}

- (NSDictionary *)getNoteData {
    return self.noteData;
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

@end
