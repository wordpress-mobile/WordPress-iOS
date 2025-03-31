import UIKit
import MessageUI

/// App selector that selects an app from a list and opens it
/// Note: it's a wrapper of UIAlertController (which cannot be sublcassed)
public class AppSelector {
    // the action sheet that will contain the list of apps that can be called
    let alertController: UIAlertController

    /// initializes the picker with a dictionary. Initialization will fail if an empty/invalid app list is passed
    /// - Parameters:
    ///   - appList: collection of apps to be added to the selector
    ///   - defaultAction: default action, if not nil, will be the first element of the list
    ///   - sourceView: the sourceView to anchor the action sheet to
    ///   - urlHandler: object that handles app URL schemes; defaults to UIApplication.shared
    public init?(with appList: [String: String],
          defaultAction: UIAlertAction? = nil,
          sourceView: UIView,
          urlHandler: URLHandler = UIApplication.shared) {
        /// inline method that builds a list of app calls to be inserted in the action sheet
        func makeAlertActions(from appList: [String: String]) -> [UIAlertAction]? {
            guard !appList.isEmpty else {
                return nil
            }

            var actions = [UIAlertAction]()
            for (name, urlString) in appList {
                guard let url = URL(string: urlString), urlHandler.canOpenURL(url) else {
                    continue
                }
                actions.append(UIAlertAction(title: AppSelectorTitles(rawValue: name)?.localized ?? name, style: .default) { _ in
                    urlHandler.open(url, options: [:], completionHandler: nil)
                })
            }

            guard !actions.isEmpty else {
                return nil
            }
            // sort the apps alphabetically
            actions = actions.sorted { $0.title ?? "" < $1.title ?? "" }
            actions.append(UIAlertAction(title: AppSelectorTitles.cancel.localized, style: .cancel, handler: nil))

            if let action = defaultAction {
                actions.insert(action, at: 0)
            }
            return actions
        }

        guard let appCalls = makeAlertActions(from: appList) else {
            return nil
        }

        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = sourceView
        alertController.popoverPresentationController?.sourceRect = sourceView.bounds
        appCalls.forEach {
            alertController.addAction($0)
        }
    }
}

/// Initializers for Email Picker
public extension AppSelector {
    /// initializes the picker with a plist file in a specified bundle
    convenience init?(with plistFile: String,
                      in bundle: Bundle,
                      defaultAction: UIAlertAction? = nil,
                      sourceView: UIView) {

        guard let plistPath = bundle.path(forResource: plistFile, ofType: "plist"),
            let availableApps = NSDictionary(contentsOfFile: plistPath) as? [String: String] else {
            return nil
        }
        self.init(with: availableApps,
                  defaultAction: defaultAction,
                  sourceView: sourceView)
    }

    /// Convenience init for a picker that calls supported email clients apps, defined in EmailClients.plist
    convenience init?(sourceView: UIView) {
        let wpAuthenticatorBundle = WordPressAuthenticator.bundle

        let plistFile = "EmailClients"
        var defaultAction: UIAlertAction?

        // if available, prepend apple mail
        if MFMailComposeViewController.canSendMail(), let url = URL(string: "message://") {
            defaultAction = UIAlertAction(title: AppSelectorTitles.appleMail.localized, style: .default) { _ in
                UIApplication.shared.open(url)
            }
        }
        self.init(with: plistFile,
                  in: wpAuthenticatorBundle,
                  defaultAction: defaultAction,
                  sourceView: sourceView)
    }
}

/// Localizable app selector titles
enum AppSelectorTitles: String {
    case appleMail
    case gmail
    case airmail
    case msOutlook
    case spark
    case yahooMail
    case fastmail
    case cancel

    var localized: String {
        switch self {
        case .appleMail:
            return NSLocalizedString("Mail (Default)", comment: "Option to select the Apple Mail app when logging in with magic links")
        case .gmail:
            return NSLocalizedString("Gmail", comment: "Option to select the Gmail app when logging in with magic links")
        case .airmail:
            return NSLocalizedString("Airmail", comment: "Option to select the Airmail app when logging in with magic links")
        case .msOutlook:
            return NSLocalizedString("Microsoft Outlook", comment: "Option to select the Microsft Outlook app when logging in with magic links")
        case .spark:
            return NSLocalizedString("Spark", comment: "Option to select the Spark email app when logging in with magic links")
        case .yahooMail:
            return NSLocalizedString("Yahoo Mail", comment: "Option to select the Yahoo Mail app when logging in with magic links")
        case .fastmail:
            return NSLocalizedString("Fastmail", comment: "Option to select the Fastmail app when logging in with magic links")
        case .cancel:
            return NSLocalizedString("Cancel", comment: "Option to cancel the email app selection when logging in with magic links")
        }
    }
}
