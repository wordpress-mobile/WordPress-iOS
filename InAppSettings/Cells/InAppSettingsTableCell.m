//
//  InAppSettingsTableCell.m
//  InAppSettingsTestApp
//
//  Created by David Keegan on 11/21/09.
//  Copyright 2009 InScopeApps{+}. All rights reserved.
//

#import "InAppSettingsTableCell.h"
#import "InAppSettingsConstants.h"

@implementation InAppSettingsTableCell

@synthesize setting;
@synthesize titleLabel, valueLabel;
@synthesize valueInput;
@synthesize canSelectCell;

#pragma mark Cell lables

- (void)setTitle{
    self.titleLabel.text = [self.setting localizedTitle];
    
    CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font];
    
    CGFloat maxTitleWidth = InAppSettingsCellTitleMaxWidth;
    if([self.setting isType:InAppSettingsPSToggleSwitchSpecifier]){
        maxTitleWidth = InAppSettingsCellTitleMaxWidth-(InAppSettingsCellToggleSwitchWidth+InAppSettingsCellPadding);
    }else if(self.accessoryType == UITableViewCellAccessoryDisclosureIndicator){
        maxTitleWidth = InAppSettingsCellTitleMaxWidth-(InAppSettingsCellDisclosureIndicatorWidth+InAppSettingsCellPadding);
    }
    if(titleSize.width > maxTitleWidth){
        titleSize.width = maxTitleWidth;
    }

    CGRect titleFrame = self.titleLabel.frame;
    titleFrame.size = titleSize;
    titleFrame.origin.x = InAppSettingsCellPadding;
    titleFrame.origin.y = (CGFloat)round((self.contentView.frame.size.height*0.5f)-(titleSize.height*0.5f))-InAppSettingsOffsetY;
    self.titleLabel.frame = titleFrame;
}

- (void)setDetail{
    [self setDetail:[self.setting getValue]];
}

- (void)setDetail:(NSString *)detail{
    //the detail is not localized
    self.valueLabel.text = detail;

    CGSize valueSize = [self.valueLabel.text sizeWithFont:self.valueLabel.font];
    
    CGRect valueFrame = self.valueLabel.frame;
    CGFloat titleRightSide = self.titleLabel.frame.size.width+InAppSettingsTablePadding;
    CGFloat valueMaxWidth = InAppSettingsScreenWidth-(titleRightSide+InAppSettingsTablePadding+InAppSettingsCellPadding*3);
    if(self.accessoryType == UITableViewCellAccessoryDisclosureIndicator){
        valueMaxWidth -= InAppSettingsCellDisclosureIndicatorWidth+InAppSettingsCellPadding;
    }
    if(valueSize.width > valueMaxWidth){
        valueSize.width = valueMaxWidth;
    }
    
    if(!InAppSettingsUseNewMultiValueLocation && [self.setting isType:InAppSettingsPSMultiValueSpecifier] && [[self.setting localizedTitle] length] == 0){
        valueFrame.origin.x = InAppSettingsCellPadding;
    }else{
        valueFrame.origin.x = (InAppSettingsScreenWidth-(InAppSettingsTotalTablePadding+InAppSettingsCellPadding))-valueSize.width;
        if(self.accessoryType == UITableViewCellAccessoryDisclosureIndicator){
            valueFrame.origin.x -= InAppSettingsCellDisclosureIndicatorWidth+InAppSettingsCellPadding;
        }
        if(titleRightSide >= valueFrame.origin.x){
            valueFrame.origin.x = titleRightSide;
        }
    }
    valueFrame.origin.y = (CGFloat)round((self.contentView.frame.size.height*0.5f)-(valueSize.height*0.5f))-InAppSettingsOffsetY;
    valueFrame.size.width = InAppSettingsScreenWidth-(valueFrame.origin.x+InAppSettingsTotalTablePadding+InAppSettingsCellPadding);
    if(self.accessoryType == UITableViewCellAccessoryDisclosureIndicator){
        valueFrame.size.width -= InAppSettingsCellDisclosureIndicatorWidth+InAppSettingsCellPadding;
    }
    
    //if the width is less then 0 just hide the label
    if(valueFrame.size.width <= 0){
        self.valueLabel.hidden = YES;
    }else{
        self.valueLabel.hidden = NO;
    }
    valueFrame.size.height = valueSize.height;
    self.valueLabel.frame = valueFrame;
}

- (void)setDisclosure:(BOOL)disclosure{
    if(disclosure){
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else{
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)setCanSelectCell:(BOOL)value{
    if(value){
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    }else{
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    canSelectCell = value;
}

#pragma mark -

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    //the docs say UITableViewCellStyleValue1 is used for settings, 
    //but it doesn't look 100% the same so we will just draw our own UILabels
    #if InAppSettingsUseNewCells
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    #else
    self = [super initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier];
    #endif
    
    if(self != nil){
        self.canSelectCell = NO;
    }
    
    return self;
}

#pragma mark implement in cell

- (void)setUIValues{
    //implement this per cell type
}

- (void)setValueDelegate:(id)delegate{
    //implement in cell
}

- (void)setupCell{
    //setup title label
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = InAppSettingsBoldFont;
    self.titleLabel.highlightedTextColor = [UIColor whiteColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
//    self.titleLabel.backgroundColor = [UIColor greenColor];
    [self.contentView addSubview:self.titleLabel];
    
    //setup value label
    self.valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.valueLabel.font = InAppSettingsNormalFont;
    self.valueLabel.textColor = InAppSettingsBlue;
    self.valueLabel.highlightedTextColor = [UIColor whiteColor];
    self.valueLabel.backgroundColor = [UIColor clearColor];
//    self.valueLabel.backgroundColor = [UIColor redColor];
    [self.contentView addSubview:self.valueLabel];
}

- (void)dealloc{
    [setting release];
    [titleLabel release];
    [valueLabel release];
    self.valueInput = nil;
    [super dealloc];
}

@end
