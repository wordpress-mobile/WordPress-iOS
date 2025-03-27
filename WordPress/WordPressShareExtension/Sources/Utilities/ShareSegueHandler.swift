// Based on this article by @NatashaTheRobot:
// https://www.natashatherobot.com/protocol-oriented-segue-identifiers-swift/

protocol ShareSegueHandler {
    associatedtype SegueIdentifier: RawRepresentable
}

extension ShareSegueHandler where Self: ShareExtensionAbstractViewController {
    func performSegue(withIdentifier identifier: ShareExtensionAbstractViewController.SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
}
