import UIKit
import NotificationCenter

class AllTimeViewController: UIViewController, NCWidgetProviding {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }

}
