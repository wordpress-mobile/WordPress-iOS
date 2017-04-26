// Based on this article by @NatashaTheRobot:
// https://www.natashatherobot.com/protocol-oriented-segue-identifiers-swift/

protocol LoginSegueHandler {
    associatedtype SegueIdentifier: RawRepresentable
}

extension LoginSegueHandler where Self: NUXAbstractViewController, SegueIdentifier.RawValue == String {
    func performSegue(withIdentifier identifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
}
