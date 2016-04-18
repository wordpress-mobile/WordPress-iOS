import Foundation

/// ViewController container, that presents a Done / Cancel button, and forwards their events to
/// the childrenViewController (which *must* implement PresentedViewController).
///
class PromptViewController: UINavigationController {
    override private init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        modalPresentationStyle = .FormSheet
    }

    @objc(initWithViewController:)
    convenience init(unsafeViewController viewController: UIViewController) {
        let container = PromptContainerViewController(viewController: viewController)
        self.init(rootViewController: container)
    }

    convenience init<T: UIViewController where T: Confirmable>(viewController: T) {
        let container = PromptContainerViewController(viewController: viewController)
        self.init(rootViewController: container)
    }

    override private init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class PromptContainerViewController : UIViewController
{
    deinit {
        stopListeningToProperties(childrenViewController)
    }
    
    init(viewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        precondition(viewController.conformsToProtocol(Confirmable))
        
        setupNavigationButtons()
        attachChildrenViewController(viewController)
        setupChildrenViewConstraints(viewController.view)
        startListeningToProperties(viewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("Not meant for Nib usage!")
    }
    
    
    
    // MARK: - Private Helpers
    
    private func attachChildrenViewController(viewController: UIViewController) {
        // Attach!
        viewController.willMoveToParentViewController(self)
        view.addSubview(viewController.view)
        addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
        
        // You stay with us, sir
        childrenViewController = viewController
    }
    
    private func setupChildrenViewConstraints(childrenView : UIView) {
        // We grow, you grow. We shrink, you shrink. Capicci?
        childrenView.translatesAutoresizingMaskIntoConstraints = false
        childrenView.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        childrenView.heightAnchor.constraintEqualToAnchor(view.heightAnchor).active = true
        childrenView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        childrenView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
    }

    
    // MARK: - KVO Rocks!
    
    private func startListeningToProperties(viewController: UIViewController) {
        for key in Properties.allKeys {
            viewController.addObserver(self, forKeyPath: key.rawValue, options: [.Initial, .New], context: nil)
        }
    }
    
    private func stopListeningToProperties(viewController: UIViewController) {
        for key in Properties.allKeys {
            viewController.removeObserver(self, forKeyPath: key.rawValue)
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let unwrappedKeyPath = keyPath, let property = Properties(rawValue: unwrappedKeyPath) else {
            return
        }
        
        switch property {
        case .titleKey:
            title = change?[NSKeyValueChangeNewKey] as? String ?? String()
        case .doneButtonEnabledKey:
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
    
    @objc @IBAction func cancelButtonWasPressed(sender: AnyObject) {
        (childrenViewController as? Confirmable)?.cancel()
    }
    
    @objc @IBAction func doneButtonWasPressed(sender: AnyObject) {
        (childrenViewController as? Confirmable)?.confirm()
    }

    
 
    // MARK: - Private Constants
    private enum Properties : String {
        case titleKey               = "title"
        case doneButtonEnabledKey   = "doneButtonEnabled"
        static let allKeys          = [titleKey, doneButtonEnabledKey]
    }
    
    // MARK: - Private Properties
    private var childrenViewController : UIViewController!
}
