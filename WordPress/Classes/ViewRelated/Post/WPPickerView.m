#import "WPPickerView.h"

static NSInteger WPPickerToolBarHeight = 44.0f;
static NSInteger WPPickerStartingWidth = 320.0f;

@interface WPPickerView ()<UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIDatePicker *datePickerView;
@property (nonatomic, strong) NSDate *startingDate;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) NSIndexPath *startingIndexes;

@end

@implementation WPPickerView

- (id)initWithDataSource:(NSArray *)dataSource andStartingIndexes:(NSIndexPath *)startingIndexes
{
    self = [self init];
    if (self) {
        if (!startingIndexes) {
            startingIndexes = [[NSIndexPath alloc] init];
            for (NSInteger i = 0; i < [dataSource count]; i++) {
                startingIndexes = [startingIndexes indexPathByAddingIndex:0];
            }
        }
        self.startingIndexes = startingIndexes;
        self.dataSource = dataSource;
        [self configureView];
    }
    return self;
}

- (id)initWithDate:(NSDate *)date
{
    self = [self init];
    if (self) {
        if (!date) {
            date = [NSDate date];
        }
        self.startingDate = date;
        [self configureView];
    }
    return self;
}

- (void)configureView
{
    [self configureToolbar];

    UIView *picker = [self viewForPicker];
    picker.frame = CGRectMake(0.0f, CGRectGetMaxY(self.toolbar.frame), WPPickerStartingWidth, CGRectGetHeight(picker.frame));

    self.frame = CGRectMake(0.0f, 0.0f, WPPickerStartingWidth, CGRectGetMaxY(picker.frame));

    [self addSubview:picker];
    [self addSubview:self.toolbar];
}

- (void)configureToolbar
{
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WPPickerStartingWidth, WPPickerToolBarHeight)];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *leftSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    leftSpacer.width = 0.0f; // Seems like the spacer is necessary for the right layout even if its width is 0.
    UIBarButtonItem *rightSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    rightSpacer.width = 6.0f;

    NSArray *buttons = [self buttonsForToolbar];
    if ([buttons count] == 0) {
        return;
    }

    NSMutableArray *items = [NSMutableArray array];
    [items addObject:leftSpacer];
    [items addObject:[buttons objectAtIndex:0]];
    for (NSInteger i = 1; i < [buttons count]; i++) {
        [items addObject:spacer];
        [items addObject:[buttons objectAtIndex:i]];
    }
    [items addObject:rightSpacer];

    self.toolbar.items = items;
}

#pragma mark - Instance Methods

- (NSArray *)buttonsForToolbar
{
    NSString *title = NSLocalizedString(@"Reset", @"Title of the reset button");
    UIBarButtonItem *resetButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(reset)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finished)];

    return @[resetButton, doneButton];
}

- (UIView *)viewForPicker
{
    if ([self isDateMode]) {
        return self.datePickerView;
    }
    return self.pickerView;
}

- (id)currentValue
{
    if ([self isDateMode]) {
        return self.datePickerView.date;
    }

    NSIndexPath *path = [[NSIndexPath alloc] init];
    for (NSInteger i = 0; i < [self.pickerView numberOfComponents]; i++) {
        path = [path indexPathByAddingIndex:[self.pickerView selectedRowInComponent:i]];
    }
    return path;
}

- (id)startingValue
{
    if ([self isDateMode]) {
        return self.startingDate;
    }
    return self.startingIndexes;
}

- (void)pickerValueChanged
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerView:didChangeValue:)]) {
        [self.delegate pickerView:self didChangeValue:[self currentValue]];
    }
}

- (BOOL)isDateMode
{
    return (self.startingDate != nil);
}

- (void)reset
{
    if ([self isDateMode]) {
        [self resetDatePicker];
    } else {
        [self resetPicker];
    }
}

- (void)finished
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerView:didFinishWithValue:)]) {
        [self.delegate pickerView:self didFinishWithValue:[self currentValue]];
    }
}

#pragma mark - Date Mode Methods

- (UIDatePicker *)datePickerView
{
    if (!_datePickerView) {
        UIDatePicker *picker = [[UIDatePicker alloc] init];
        picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        picker.datePickerMode = UIDatePickerModeDateAndTime;
        picker.date = self.startingDate;
        picker.minuteInterval = 5;
        [picker addTarget:self action:@selector(pickerValueChanged) forControlEvents:UIControlEventValueChanged];
        self.datePickerView = picker;
    }
    return _datePickerView;
}

- (void)resetDatePicker
{
    if ([self.datePickerView.date isEqualToDate:self.startingDate]) {
        return;
    }
    self.datePickerView.date = self.startingDate;
    [self pickerValueChanged];
}

#pragma mark - Picker Mode Methods

- (UIPickerView *)pickerView
{
    if (!_pickerView) {
        UIPickerView *picker = [[UIPickerView alloc] init];
        picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        picker.dataSource = self;
        picker.delegate = self;
        picker.showsSelectionIndicator = YES;
        self.pickerView = picker;
        [self setPickerStartingIndexes];
    }
    return _pickerView;
}

- (BOOL)setPickerStartingIndexes
{
    BOOL changed = NO;

    for (NSUInteger i = 0; i < [self.startingIndexes length]; i++) {
        NSUInteger index = [self.startingIndexes indexAtPosition:i];
        if (index != [self.pickerView selectedRowInComponent:i]) {
            changed = YES;
        }
        [self.pickerView selectRow:index inComponent:i animated:YES];
    }

    return changed;
}

- (NSArray *)arrayForComponent:(NSInteger)component
{
    return [self.dataSource objectAtIndex:component];
}

- (void)resetPicker
{
    BOOL changed = [self setPickerStartingIndexes];
    if (changed) {
        [self pickerValueChanged];
    }
}

#pragma mark - UIPickerView Delegate Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return [self.dataSource count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[self arrayForComponent:component] count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[self arrayForComponent:component] objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self pickerValueChanged];
}

@end
