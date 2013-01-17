//
//  Note.m
//  WordPress
//
//  Created by Beau Collins on 11/18/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "Note.h"
#import "NSString+Helpers.h"
#import "JSONKit.h"

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
@synthesize commentText = _commentText, noteData = _noteData;


+ (BOOL)syncNotesWithResponse:(NSArray *)notesData withManagedObjectContext:(NSManagedObjectContext *)context {
    
    [notesData enumerateObjectsUsingBlock:^(id noteData, NSUInteger idx, BOOL *stop) {
        [self createOrUpdateNoteWithData:noteData withManagedObjectContext:context];
    }];
    
    NSError *error;
    if(![context save:&error]){
        NSLog(@"Failed to sync notes: %@", error);
        return NO;
    } else {
        return YES;
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
        WPFLog(@"Error pruning old notes: %@", error);
        return;
    }
    for (Note *note in notes) {
        [context deleteObject:note];
    }
    if(![context save:&error]){
        WPFLog(@"Failed to save after pruning notes: %@", error);
    }
    [context save:&error];
}

+ (void)removeAllNotesWithContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.includesPropertyValues = NO;
    NSError *error;
    NSArray *notes = [context executeFetchRequest:request error:&error];
    if (notes) {
        for (Note *note in notes) {
            [context deleteObject:note];
        }
    }
    [context save:&error];
}

- (NSDictionary *)getNoteData {
    return self.noteData;
}

+ (void)createOrUpdateNoteWithData:(NSDictionary *)noteData withManagedObjectContext:(NSManagedObjectContext *)context {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.predicate = [NSPredicate predicateWithFormat:@"noteID = %@", [noteData objectForKey:@"id"]];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    request.fetchLimit = 1;
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if(error != nil){
        NSLog(@"Error finding note: %@", error);
        return;
    }
    Note *note;
    if ([results count] > 0) { // find a note so just update it
        note = (Note *)[results objectAtIndex:0];
    } else {
        note = (Note *)[NSEntityDescription insertNewObjectForEntityForName:@"Note"
                                                     inManagedObjectContext:context];
        
        note.noteID = [noteData objectForKey:@"id"];
    }
    
    [note syncAttributes:noteData];

}

- (void)syncAttributes:(NSDictionary *)noteData {
    self.payload = [noteData JSONData];
    self.noteData = [self.payload mutableObjectFromJSONData];
    self.type = [noteData objectForKey:@"type"];
    NSString *subject = [[noteData objectForKey:@"subject"] objectForKey:@"text"];
    if (!subject)
        subject = [[noteData objectForKey:@"subject"] objectForKey:@"html"];
    self.subject = [subject trim];
    self.icon = [[noteData objectForKey:@"subject"] objectForKey:@"icon"];
    NSInteger timestamp = [[noteData objectForKey:@"timestamp"] integerValue];
    self.timestamp = [NSNumber numberWithInteger:timestamp];
    NSInteger unread = [[noteData objectForKey:@"unread"] integerValue];
    self.unread = [NSNumber numberWithInteger:unread];
    [self parseComment];
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
        _noteData = [self.payload mutableObjectFromJSONData];
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
