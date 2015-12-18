#ifndef MenusDesign_h
#define MenusDesign_h

typedef NS_ENUM(NSUInteger) {
    MenuItemIconNone,
    MenuItemIconDefault,
    MenuItemIconEdit,
    MenuItemIconAdd,
}MenuItemIconType;

typedef NS_ENUM(NSUInteger) {
    
    MenuItemTypePage,
    MenuItemTypeLink,
    MenuItemTypeCategory,
    MenuItemTypeTag,
    MenuItemTypePost,
    MenuItemTypeCustom
    
}MenuItemType;

static CGFloat const MenusDesignDefaultCornerRadius = 4.0;
static CGFloat const MenusDesignDefaultContentSpacing = 18.0;
static CGFloat const MenusDesignItemIconSize = 10.0;

static inline UIEdgeInsets MenusDesignDefaultInsets() {
    return UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
}

static NSString * MenusDesignItemIconImageNameForType(MenuItemIconType type)
{
    NSString *name;
    switch (type) {
        case MenuItemIconNone:
            name = nil;
            break;
        case MenuItemIconDefault:
            name = @"icon-menus-document";
            break;
        case MenuItemIconEdit:
            name = @"icon-menus-edit";
            break;
        case MenuItemIconAdd:
            name = @"icon-menus-plus";
            break;
    }
    
    return name;
}

#endif /* MenusDesign_h */
