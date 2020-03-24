import UIKit

class ReaderTabViewController: UIViewController {

    @objc convenience init(view: ReaderTabView) {
        self.init()
        self.view = view
        self.title = NSLocalizedString("Reader", comment: "The default title of the Reader")
    }
}
