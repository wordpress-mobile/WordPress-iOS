//
//  UITableViewTextFieldCell.m
//  WordPress
//
//  Created by Jorge Bernal on 4/27/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "UITableViewTextFieldCell.h"

@interface UITableViewTextFieldCell () <UITextFieldDelegate>

@end

@implementation UITableViewTextFieldCell
@synthesize textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textField = [[UITextField alloc] initWithFrame:self.bounds];
        self.textField.adjustsFontSizeToFitWidth = YES;
        self.textField.textColor = [UIColor blackColor];
        self.textField.backgroundColor = [UIColor clearColor];
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.textAlignment = UITextAlignmentLeft;
        self.textField.clearButtonMode = UITextFieldViewModeNever;
        self.textField.enabled = YES;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.delegate = self;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        
        [self addSubview:self.textField];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame;

    CGSize labelSize = [self.textLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:17]];
    labelSize.width = ceil(labelSize.width/5) * 5; // Round to upper 5

    if (IS_IPAD) {
        frame = CGRectMake(labelSize.width + 60,
                           self.textLabel.frame.origin.y,
                           self.frame.size.width - labelSize.width - 100,
                           self.textLabel.frame.size.height);
    } else {
        frame = CGRectMake(labelSize.width + 30,
                           self.textLabel.frame.origin.y,
                           self.frame.size.width - labelSize.width - 50,
                           self.textLabel.frame.size.height);
    }
    self.textField.frame = frame;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.textField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.shouldDismissOnReturn) {
        [self.textField resignFirstResponder];
    } else {
        if (self.delegate) {
            [self.delegate cellWantsToSelectNextField:self];
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellTextDidChange:)]) {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.delegate cellTextDidChange:self];
        });
    }
    return YES;
}

- (void)setShouldDismissOnReturn:(BOOL)shouldDismissOnReturn {
    _shouldDismissOnReturn = shouldDismissOnReturn;
    if (shouldDismissOnReturn) {
        self.textField.returnKeyType = UIReturnKeyDone;
    } else {
        self.textField.returnKeyType = UIReturnKeyNext;
    }
}

@end
