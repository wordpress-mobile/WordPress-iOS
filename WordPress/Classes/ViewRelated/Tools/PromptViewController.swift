import Foundation
import UIKit


/// Wraps a given UIViewController, that conforms to the Confirmable Protocol, into:
/// -   A PromptViewController instance, which deals with the NavigationItem buttons
/// -   (And verything) inside a UINavigationController instance.
///
public func PromptViewController<T: UIViewController where T: Confirmable>(viewController: T) -> UINavigationController {
    let viewController = PromptContainerViewController(viewController: viewController)
    return UINavigationController(rootViewController: viewController)
}


/// ViewController container, that presents a Done / Cancel button, and forwards their events to
/// the childrenViewController (which *must* implement the Confirmable protocol).
///
private class PromptContainerViewController : UIViewController
{
    /// MARK: - Initializers / Deinitializers

    deinit {
        stopListeningToProperties(childViewController)
    }

    init(viewController: UIViewController) {
        // You stay with us, sir
        childViewController = viewController

        super.init(nibName: nil, bundle: nil)
        precondition(viewController.conformsToProtocol(Confirmable))

        setupNavigationButtons()
        attachChildViewController(viewController)
        setupChildViewConstraints(viewController.view)
        startListeningToProperties(viewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not meant for Nib usage!")
    }



    // MARK: - Private Helpers

    private func attachChildViewController(viewController: UIViewController) {
        // Attach!
        viewController.willMoveToParentViewController(self)
        view.addSubview(viewController.view)
        addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
    }

    private func setupChildViewConstraints(childrenView : UIView) {
        // We grow, you grow. We shrink, you shrink. Capicci?
        childrenView.translatesAutoresizingMaskIntoConstraints = false
        childrenView.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        childrenView.heightAnchor.constraintEqualToAnchor(view.heightAnchor).active = true
        childrenView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        childrenView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
    }


    // MARK: - KVO Rocks!

    private func startListeningToProperties(viewController: UIViewController) {
        for key in Properties.all where viewController.respondsToSelector(NSSelectorFromString(key.rawValue)) {
            viewController.addObserver(self, forKeyPath: key.rawValue, options: [.Initial, .New], context: nil)
        }
    }

    private func stopListeningToProperties(viewController: UIViewController) {
        for key in Properties.all where viewController.respondsToSelector(NSSelectorFromString(key.rawValue)) {
            viewController.removeObserver(self, forKeyPath: key.rawValue)
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let unwrappedKeyPath = keyPath, let property = Properties(rawValue: unwrappedKeyPath) else {
            return
        }

        switch property {
        case .title:
            title = change?[NSKeyValueChangeNewKey] as? String ?? String()
        case .doneButtonEnabled:
            navigationItem.rightBarButtonItem?.enabled = change?[NSKeyValueChangeNewKey] as? Bool ?? true
        }
    }


    // MARK: - Navigation Buttons

    private func setupNavigationButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                                           target: self,
                                                           action: #selector(cancelButtonWasPressed))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done,
                                                            target: self,
                                                            action: #selector(doneButtonWasPressed))
    }

    @objc
    @IBAction func cancelButtonWasPressed(sender: AnyObject) {
        (childViewController as? Confirmable)?.cancel()
    }

    @objc
    @IBAction func doneButtonWasPressed(sender: AnyObject) {
        (childViewController as? Confirmable)?.confirm()
    }



    // MARK: - Private Constants
    private enum Properties : String {
        case title              = "title"
        case doneButtonEnabled  = "doneButtonEnabled"
        static let all          = [title, doneButtonEnabled]
    }

    // MARK: - Private Properties
    private let childViewController : UIViewController
}
