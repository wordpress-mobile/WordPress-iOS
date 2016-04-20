import Foundation
import UIKit

class PersonViewController : UITableViewController
{
    var person : Person!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = person?.fullName
    }
}
