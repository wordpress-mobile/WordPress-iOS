import Foundation
import UIKit


/// Wraps a given UIViewController, that conforms to the Confirmable Protocol, into:
/// -   A PromptViewController instance, which deals with the NavigationItem buttons
/// -   (And verything) inside a UINavigationController instance.
///
public func PromptViewController<T: UIViewController>(_ viewController: T) -> UINavigationController where T: Confirmable {
    let viewController = PromptContainerViewController(viewController: viewController)
    return UINavigationController(rootViewController: viewController)
}


/// ViewController container, that presents a Done / Cancel button, and forwards their events to
/// the childrenViewController (which *must* implement the Confirmable protocol).
///
private class PromptContainerViewController: UIViewController {
    // MARK: - Initializers / Deinitializers

    deinit {
        stopListeningToProperties(childViewController)
    }

    @objc init(viewController: UIViewController) {
        // You stay with us, sir
        childViewController = viewController

        super.init(nibName: nil, bundle: nil)
        precondition(viewController.conforms(to: Confirmable.self))

        setupNavigationButtons()
        attachChildViewController(viewController)
        setupChildViewConstraints(viewController.view)
        startListeningToProperties(viewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not meant for Nib usage!")
    }



    // MARK: - Private Helpers

    fileprivate func attachChildViewController(_ viewController: UIViewController) {
        // Attach!
        viewController.willMove(toParent: self)
        view.addSubview(viewController.view)
        addChild(viewController)
        viewController.didMove(toParent: self)
    }

    fileprivate func setupChildViewConstraints(_ childrenView: UIView) {
        // We grow, you grow. We shrink, you shrink. Capicci?
        childrenView.translatesAutoresizingMaskIntoConstraints = false
        childrenView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        childrenView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        childrenView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        childrenView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }


    // MARK: - KVO Rocks!

    fileprivate func startListeningToProperties(_ viewController: UIViewController) {
        for key in Properties.all where viewController.responds(to: NSSelectorFromString(key.rawValue)) {
            viewController.addObserver(self, forKeyPath: key.rawValue, options: [.initial, .new], context: nil)
        }
    }

    fileprivate func stopListeningToProperties(_ viewController: UIViewController) {
        for key in Properties.all where viewController.responds(to: NSSelectorFromString(key.rawValue)) {
            viewController.removeObserver(self, forKeyPath: key.rawValue)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let unwrappedKeyPath = keyPath, let property = Properties(rawValue: unwrappedKeyPath) else {
            return
        }

        switch property {
        case .title:
            title = change?[NSKeyValueChangeKey.newKey] as? String ?? String()
        case .doneButtonEnabled:
            navigationItem.rightBarButtonItem?.isEnabled = change?[NSKeyValueChangeKey.newKey] as? Bool ?? true
        }
    }


    // MARK: - Navigation Buttons

    fileprivate func setupNavigationButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancelButtonWasPressed))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneButtonWasPressed))
    }

    @objc
    @IBAction func cancelButtonWasPressed(_ sender: AnyObject) {
        (childViewController as? Confirmable)?.cancel()
    }

    @objc
    @IBAction func doneButtonWasPressed(_ sender: AnyObject) {
        (childViewController as? Confirmable)?.confirm()
    }



    // MARK: - Private Constants
    fileprivate enum Properties: String {
        case title              = "title"
        case doneButtonEnabled  = "doneButtonEnabled"
        static let all          = [title, doneButtonEnabled]
    }

    // MARK: - Private Properties
    fileprivate let childViewController: UIViewController
}
