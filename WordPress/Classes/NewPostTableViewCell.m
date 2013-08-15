//
//  NewPostTableViewCell.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewPostTableViewCell.h"
#import "Post.h"
#import "NSString+XMLExtensions.h"

@interface NewPostTableViewCell() {
    AbstractPost __weak *_post;
    UILabel *_statusLabel;
    UILabel *_titleLabel;
    UILabel *_dateLabel;
}

@end

@implementation NewPostTableViewCell

CGFloat const NewPostTableViewCellStandardOffset = 16.0;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:238/255.0f green:238/255.0f blue:238/255.0f alpha:1.0f];
        
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.backgroundColor = [UIColor clearColor];
        _statusLabel.textAlignment = NSTextAlignmentLeft;
        _statusLabel.numberOfLines = 0;
        _statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _statusLabel.font = [[self class] statusFont];
        _statusLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _statusLabel.textColor = [UIColor colorWithRed:30/255.0f green:140/255.0f blue:190/255.0f alpha:1.0f];
        [self.contentView addSubview:_statusLabel];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 0;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.font = [[self class] titleFont];
        _titleLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _titleLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:_titleLabel];
        
        _dateLabel = [[UILabel alloc] init];
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.textAlignment = NSTextAlignmentLeft;
        _dateLabel.numberOfLines = 0;
        _dateLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _dateLabel.font = [[self class] dateFont];
        _dateLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _dateLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_dateLabel];
    }
    return self;
}


- (void)prepareForReuse{
    [super prepareForReuse];
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat maxWidth = CGRectGetWidth(self.bounds);

    _statusLabel.frame = [[self class] statusLabelFrameForPost:self.post maxWidth:maxWidth];
    _titleLabel.frame = [[self class] titleLabelFrameForPost:self.post previousFrame:_statusLabel.frame maxWidth:maxWidth];
    _dateLabel.frame = [[self class] dateLabelFrameForPost:self.post previousFrame:_titleLabel.frame maxWidth:maxWidth];
}

+ (CGFloat)rowHeightForPost:(AbstractPost *)post andWidth:(CGFloat)width;
{
    CGRect statusFrame = [[self class] statusLabelFrameForPost:post maxWidth:width];
    CGRect titleFrame = [[self class] titleLabelFrameForPost:post previousFrame:statusFrame maxWidth:width];
    CGRect dateFrame = [[self class] dateLabelFrameForPost:post previousFrame:titleFrame maxWidth:width];
    
    return CGRectGetMaxY(dateFrame) + NewPostTableViewCellStandardOffset;
}

- (void)runSpinner:(BOOL)value
{
}

- (AbstractPost *)post
{
    return _post;
}

- (void)setPost:(AbstractPost *)post
{
    if (_post != post) {
        _post = post;
        
        _titleLabel.text = [[self class] titleText:post];
        _statusLabel.text = [[self class] statusTextForPost:post];
        _statusLabel.textColor = [[self class] statusColorForPost:post];
        _dateLabel.text = [[self class] dateText:post];        
    }
}

+ (UIFont *)statusFont
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:10.0];
}

+ (NSString *)statusTextForPost:(AbstractPost *)post
{
    if (post.remoteStatus == AbstractPostRemoteStatusSync) {
        if ([post.status isEqualToString:@"pending"]) {
            return [NSLocalizedString(@"Pending", @"") uppercaseString];
        } else if ([post.status isEqualToString:@"draft"]) {
            return [post.statusTitle uppercaseString];
        } else {
            return @"";
        }
    } else {
        return [AbstractPost titleForRemoteStatus:@((int)post.remoteStatus)];
    }
}

+ (UIColor *)statusColorForPost:(AbstractPost *)post
{
    if (post.remoteStatus == AbstractPostRemoteStatusSync) {
        if ([post.status isEqualToString:@"pending"]) {
            return [UIColor lightGrayColor];
        } else if ([post.status isEqualToString:@"draft"]) {
            return [UIColor colorWithRed:213/255.0f green:78/255.0f blue:33/255.0f alpha:1.0f];
        } else {
            return [UIColor blackColor];
        }
    } else {
        if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
            return [UIColor colorWithRed:46/255.0f green:162/255.0f blue:204/255.0f alpha:1.0f];
        } else if (post.remoteStatus == AbstractPostRemoteStatusFailed) {
            return [UIColor redColor];
        } else {
            return [UIColor blackColor];
        }
    }
}

+ (UIFont *)titleFont
{
    return [UIFont fontWithName:@"OpenSans" size:18.0];
}

+ (NSString *)titleText:(AbstractPost *)post
{
    NSString *title = [[post valueForKey:@"postTitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (title == nil || ([title length] == 0)) {
        title = NSLocalizedString(@"(no title)", @"");
    }
    return [title stringByDecodingXMLCharacters];
}

+ (UIFont *)dateFont
{
    return [UIFont fontWithName:@"OpenSans" size:12.0];
}

+ (NSString *)dateText:(AbstractPost *)post
{
    static NSDateFormatter *dateFormatter = nil;
    
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd '|' HH:mm a"];
    }
    
    NSDate *date = [post valueForKey:@"dateCreated"];
    return [dateFormatter stringFromDate:date];
}


#pragma mark - Private Methods

+ (CGFloat)textWidth:(CGFloat)maxWidth
{
    return maxWidth - 2*NewPostTableViewCellStandardOffset;
}

+ (CGRect)statusLabelFrameForPost:(AbstractPost *)post maxWidth:(CGFloat)maxWidth
{
    NSString *statusText = [self statusTextForPost:post];
    if ([statusText length] != 0) {
       CGSize size = [statusText sizeWithFont:[self statusFont] constrainedToSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        return CGRectMake(NewPostTableViewCellStandardOffset, NewPostTableViewCellStandardOffset, size.width, size.height);
    } else {
        return CGRectMake(0, NewPostTableViewCellStandardOffset, 0, 0);
    }
}

+ (CGRect)titleLabelFrameForPost:(AbstractPost *)post previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    CGSize size = [[[self class] titleText:post] sizeWithFont:[[self class] titleFont] constrainedToSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    return CGRectIntegral(CGRectMake(NewPostTableViewCellStandardOffset, CGRectGetMaxY(previousFrame), size.width, size.height));
}

+ (CGRect)dateLabelFrameForPost:(AbstractPost *)post previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    CGSize size = [[[self class] dateText:post] sizeWithFont:[[self class] dateFont] constrainedToSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    return CGRectIntegral(CGRectMake(NewPostTableViewCellStandardOffset, CGRectGetMaxY(previousFrame), size.width, size.height));
}


@end
