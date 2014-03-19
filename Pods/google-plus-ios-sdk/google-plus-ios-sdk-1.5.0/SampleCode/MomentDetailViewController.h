@class GTLPlusMoment;

// View controller to present detailed information about a |GTLPlusMoment| object.
// The properties of the moment are presented as cells in a table view.
@interface MomentDetailViewController : UITableViewController

// The moment whose data is presented in the table view.
@property(weak, nonatomic) GTLPlusMoment *moment;

// Sets the moment property to the |moment| object, and updates the list of keys
// for |moment.target| and |moment.result|.
- (void)resetToMoment:(GTLPlusMoment *)moment;

@end
