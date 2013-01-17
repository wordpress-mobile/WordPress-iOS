//
//  Note.m
//  WordPress
//
//

#import "Note.h"
#import "AFImageRequestOperation.h"
#import "NSString+Helpers.h"


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

@property (nonatomic, strong) AFImageRequestOperation *operation;
@property (readwrite, nonatomic, strong) NSString *commentText;

@end

@implementation Note

- (id)initWithNoteData:(NSDictionary *)noteData {
    if (self = [super init]) {
        self.noteData = noteData;
        self.noteIconImage = [UIImage imageNamed:@"note_icon_placeholder"];
    }
    return self;
}

- (void)setNoteData:(NSDictionary *)noteData {
    if (_noteData != noteData) {
        _noteData = noteData;
        [self loadImage];
        [self parseComment];
    }
}

- (NSString *)subject {
    NSString *subject = (NSString *)[[self.noteData objectForKey:@"subject"] objectForKey:@"text"];
    return [subject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)type {
    return [self.noteData objectForKey:@"type"];
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
    NSString *unread = (NSString*)[self.noteData objectForKey:@"unread"];
    return [unread isEqualToString:@"1"];
}

- (BOOL)isRead {
    return ![self isUnread];
}

/*
 * TODO: image caching to disk?
 */
- (void)loadImage {
    NSString *url = [[self.noteData objectForKey:@"subject"] objectForKey:@"icon"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    if (self.operation != nil) {
        [self.operation cancel];
    }
    self.operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
        self.noteIconImage = image;
    }];
    [self.operation start];
}

/*
 * Strips HTML Tags and converst html entites
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
