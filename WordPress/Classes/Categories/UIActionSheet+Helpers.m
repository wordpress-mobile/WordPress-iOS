#import "UIActionSheet+Helpers.h"



#pragma mark =====================================================================================
#pragma mark Private Methods
#pragma mark =====================================================================================

@interface UIActionSheet (Private) <UIActionSheetDelegate>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
+ (NSMutableDictionary*)blockMap;
@end



#pragma mark =====================================================================================
#pragma mark UIActionSheet Helpers
#pragma mark =====================================================================================

@implementation UIActionSheet (Helpers)

- (instancetype)initWithTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                   completion:(UIActionSheetCompletion)completion
{
    self = [self initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    if (self) {
        UIActionSheetCompletion completionCopy = [completion copy];
        [[[self class] blockMap] setObject:completionCopy forKey:[NSValue valueWithPointer:(__bridge const void *)(self)]];
        
        // Add the otherButtonTitles
        NSInteger lastButtonIndex = -1;
        for(NSString* buttonTitle in otherButtonTitles) {
            [self addButtonWithTitle:buttonTitle];
            ++lastButtonIndex;
        }

        if (cancelButtonTitle) {
            [self addButtonWithTitle:cancelButtonTitle];
            self.cancelButtonIndex = ++lastButtonIndex;
        }

        if (destructiveButtonTitle) {
            [self addButtonWithTitle:destructiveButtonTitle];
            self.destructiveButtonIndex = ++lastButtonIndex;
        }
    }
    
    return self;
}


#pragma mark - Private Methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    id mapKey                           = [NSValue valueWithPointer:(__bridge const void *)(actionSheet)];
    NSString *title                     = [self buttonTitleAtIndex:buttonIndex];
    NSMutableDictionary* map            = [[self class] blockMap];
    
    UIActionSheetCompletion completion  = [map objectForKey:mapKey];
    if (completion) {
        completion(title);
        [map removeObjectForKey:mapKey];
    }
}


#pragma mark - Static Helpers

+ (NSMutableDictionary*)blockMap
{
    static NSMutableDictionary* _blockMap;
    static dispatch_once_t      _once;
    
    dispatch_once(&_once, ^{
        _blockMap = [[NSMutableDictionary alloc] init];
    });
    
    return _blockMap;
}

@end
