protocol LoginSegueHandler {
    associatedtype SegueIdentifier: RawRepresentable
}

extension LoginSegueHandler where Self: UIViewController, SegueIdentifier.RawValue == String {
    func performSegue(withIdentifier identifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
}
