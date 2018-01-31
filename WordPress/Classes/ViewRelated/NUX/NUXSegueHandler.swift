// Based on this article by @NatashaTheRobot:
// https://www.natashatherobot.com/protocol-oriented-segue-identifiers-swift/

protocol NUXSegueHandler {
    associatedtype SegueIdentifier: RawRepresentable
}

extension NUXSegueHandler where Self: NUXAbstractViewController {
    func performSegue(withIdentifier identifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
}

extension NUXSegueHandler where Self: NUXViewController {
    func performSegue(withIdentifier identifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
}
