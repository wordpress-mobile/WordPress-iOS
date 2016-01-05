import UIKit
import WordPressShared.WPStyleGuide

/**
 *  @brief      UISearchController with configurable status bar style
 *  @details    Matches appearance of WPSearchController
 */
public class StyledSearchController: UISearchController
{
    // MARK: - Exposed properties

    public var statusBarStyle: UIStatusBarStyle = .LightContent {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    // MARK: - UIViewController

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        applyStyles()
    }

    private func applyStyles() {
        dimsBackgroundDuringPresentation = false
        hidesNavigationBarDuringPresentation = false
        
        searchBar.autocapitalizationType = .None
        searchBar.autocorrectionType = .No
    
        searchBar.barStyle = .Black
        searchBar.barTintColor = WPStyleGuide.wordPressBlue()
        searchBar.tintColor = WPStyleGuide.grey()
    
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchController.self]).textColor = UIColor.whiteColor()

        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = WPStyleGuide.wordPressBlue().CGColor
    
        searchBar.setImage(UIImage(named: "icon-clear-textfield"), forSearchBarIcon: .Clear, state: .Normal)
        searchBar.setImage(UIImage(named: "icon-post-list-search"), forSearchBarIcon: .Search, state: .Normal)
    }
  
    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusBarStyle
    }
}
