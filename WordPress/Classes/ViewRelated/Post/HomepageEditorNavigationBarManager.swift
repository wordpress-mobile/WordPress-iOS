import Foundation

protocol HomepageEditorNavigationBarManagerDelegate: PostEditorNavigationBarManagerDelegate {
    var continueButtonText: String { get }

    func navigationBarManager(_ manager: HomepageEditorNavigationBarManager, continueWasPressed sender: UIButton)
}

class HomepageEditorNavigationBarManager: PostEditorNavigationBarManager {
    weak var homepageEditorNavigationBarManagerDelegate: HomepageEditorNavigationBarManagerDelegate?

    override weak var delegate: PostEditorNavigationBarManagerDelegate? {
        get {
            return homepageEditorNavigationBarManagerDelegate
        }
        set {
            if let newDelegate = newValue {
                if let newHomepageDelegate = newDelegate as? HomepageEditorNavigationBarManagerDelegate {
                    homepageEditorNavigationBarManagerDelegate = newHomepageDelegate
                } else {
                    // This should not happen, but fail fast in case
                    fatalError("homepageEditorNavigationBarManagerDelegate must be of type HomepageEditorNavigationBarManagerDelegate?")
                }
            } else {
                homepageEditorNavigationBarManagerDelegate = nil
            }
        }
    }

    /// Continue Button
    private(set) lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(continueButtonTapped(sender:)), for: .touchUpInside)
        button.setTitle(homepageEditorNavigationBarManagerDelegate?.continueButtonText ?? "", for: .normal)
        button.sizeToFit()
        button.isEnabled = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    /// Continue Button
    private(set) lazy var continueBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(customView: self.continueButton)
        return button
    }()

    @objc private func continueButtonTapped(sender: UIButton) {
        homepageEditorNavigationBarManagerDelegate?.navigationBarManager(self, continueWasPressed: sender)
    }

    override var leftBarButtonItems: [UIBarButtonItem] {
        return []
    }

    override var rightBarButtonItems: [UIBarButtonItem] {
        return [moreBarButtonItem, continueBarButtonItem, separatorButtonItem]
    }
}
