import UIKit
import WordPressShared

class LoginEpilogueViewController: UIViewController {
    var originalPresentingVC: UIViewController?
    var dismissBlock: ((_ cancelled: Bool) -> Void)?
    @IBOutlet var buttonPanel: UIView?
    @IBOutlet var shadowView: UIView?
    var tableViewController: LoginEpilogueTableView?
    var epilogueUserInfo: LoginEpilogueUserInfo?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let info = epilogueUserInfo {
            tableViewController?.epilogueUserInfo = info
        } else {
            // The self-hosted flow sets user info,  If no user info is set, assume
            // a wpcom flow and try the default wp account.
            let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            if let account = service.defaultWordPressComAccount() {
                tableViewController?.epilogueUserInfo = LoginEpilogueUserInfo(account: account)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? LoginEpilogueTableView {
            tableViewController = vc
        }
    }

    // @IBAction to allow to set the selector for target in the storyboard
    @IBAction func unwindOut(segue: UIStoryboardSegue) {
        dismissBlock?(false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        colorPanelBasedOnTableViewContents()
    }

    func colorPanelBasedOnTableViewContents() {
        var tableVC: UITableViewController?
        for childVC in childViewControllers {
            if let childVC = childVC as? UITableViewController {
                tableVC = childVC
            }
        }

        guard let table = tableVC?.tableView,
            let buttonPanel = buttonPanel else {
            return
        }

        let contentSize = table.contentSize
        let screenHeight = UIScreen.main.bounds.size.height
        let panelHeight = buttonPanel.frame.size.height

        if screenHeight - panelHeight > contentSize.height {
            buttonPanel.backgroundColor = WPStyleGuide.lightGrey()
            shadowView?.isHidden = true
        } else {
            buttonPanel.backgroundColor = UIColor.white
            shadowView?.isHidden = false
        }
    }
}
