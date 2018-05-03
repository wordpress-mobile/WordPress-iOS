// Based on this article by @NatashaTheRobot:
// https://www.natashatherobot.com/protocol-oriented-segue-identifiers-swift/

public protocol NUXSegueHandler {
    associatedtype SegueIdentifier: RawRepresentable
}

extension NUXSegueHandler where Self: NUXViewController {
    public func performSegue(withIdentifier identifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
}
