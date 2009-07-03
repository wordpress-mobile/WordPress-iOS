//
//  LocalDraftsTableViewCell.h
//  WordPress
//
//  Created by Josh Bassett on 1/07/09.
//

#import <Foundation/Foundation.h>

@interface LocalDraftsTableViewCell : UITableViewCell {
    UILabel *_badgeLabel;
}

@property (readonly) UILabel *badgeLabel;

@end
