import Foundation


/// Protocol that defines the methods required by PromptViewController's Children(s).
///
@objc
protocol PresentedViewController
{
    var doneButtonEnabled : Bool { get }
    func cancelButtonWasPressed(sender: AnyObject)
    func doneButtonWasPressed(sender: AnyObject)
}


/// ViewController container, that presents a Done / Cancel button, and forwards their events to
/// the childrenViewController (which *must* implement PresentedViewController).
///
class PromptViewController : UIViewController
{
    deinit {
        stopListeningToProperties(childViewController)
    }
    
    init(viewController: UIViewController) {
        // You stay with us, sir
        childViewController = viewController
        
        super.init(nibName: nil, bundle: nil)
        assert(viewController.conformsToProtocol(PresentedViewController))
        
        setupNavigationButtons()
        attachChildrenViewController(viewController)
        setupChildrenViewConstraints(viewController.view)
        startListeningToProperties(viewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not meant for Nib usage!")
    }
    
    
    
    // MARK: - Private Helpers
    
    private func attachChildrenViewController(viewController: UIViewController) {
        // Attach!
        viewController.willMoveToParentViewController(self)
        view.addSubview(viewController.view)
        addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
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
        for key in Properties.all {
            viewController.addObserver(self, forKeyPath: key.rawValue, options: [.Initial, .New], context: nil)
        }
    }
    
    private func stopListeningToProperties(viewController: UIViewController) {
        for key in Properties.all {
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
    
    @IBAction func cancelButtonWasPressed(sender: AnyObject) {
        (childViewController as? PresentedViewController)?.cancelButtonWasPressed(sender)
    }
    
    @IBAction func doneButtonWasPressed(sender: AnyObject) {
        (childViewController as? PresentedViewController)?.doneButtonWasPressed(sender)
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
