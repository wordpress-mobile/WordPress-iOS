import UIKit
import WordPressShared
import WordPressKit

class ShareModularViewController: ShareExtensionAbstractViewController {

    private let topStackView = UIStackView()

    fileprivate let sitePickerTableViewController: SitePickerViewController = {
        return SitePickerViewController()
    }()

    fileprivate let modulesTableViewController: UITableViewController = {
        let storyboard = UIStoryboard(name: "ShareExtension", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ModulesTableViewController") as! UITableViewController
    }()

    fileprivate let summaryLabel: UILabel = {
        $0.text = "I'm a summary label!!"
        return $0
    }(UILabel())

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStackView()
        addContentController(modulesTableViewController, to: topStackView)
        topStackView.addArrangedSubview(summaryLabel)
        addContentController(sitePickerTableViewController, to: topStackView)
        sitePickerTableViewController.sitePickerDelegate = self
    }
}

// MARK: - Misc Private helpers

extension ShareModularViewController: SitePickerDelegate{
    func didSelectSite(siteId: Int, description: String?) {
        selectedSiteID = siteId
    }
}

// MARK: - Misc Private helpers

private extension ShareModularViewController {

    private func setupStackView() {

        topStackView.axis = .vertical
        topStackView.alignment = .fill
        topStackView.distribution = .fill
        topStackView.spacing = 8.0
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topStackView)

        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            topStackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            topStackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            topStackView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 8.0),
            bottomLayoutGuide.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 8.0)
            ])
    }

    private func addContentController(_ child: UIViewController, to stackView: UIStackView) {

        addChildViewController(child)
        stackView.addArrangedSubview(child.view)
        child.didMove(toParentViewController: self)
    }

    private func removeContentController(_ child: UIViewController, from stackView: UIStackView) {

        child.willMove(toParentViewController: nil)
        stackView.removeArrangedSubview(child.view)
        child.view.removeFromSuperview()
        child.removeFromParentViewController()
    }
}

// MARK: - Backend Interaction

private extension ShareModularViewController {

    func savePostToRemoteSite() {
        guard let _ = oauth2Token, let siteID = selectedSiteID else {
            fatalError("Need to have an oauth token and site ID selected.")
        }

        // FIXME: Save the last used site
        //        if let siteName = selectedSiteName {
        //            ShareExtensionService.configureShareExtensionLastUsedSiteID(siteID, lastUsedSiteName: siteName)
        //        }

        // Proceed uploading the actual post
        if shareData.sharedImageDict.values.count > 0 {
            uploadPostWithMedia(subject: shareData.title,
                                body: shareData.contentBody,
                                status: shareData.postStatus,
                                siteID: siteID,
                                requestEnqueued: {
                                    self.tracks.trackExtensionPosted(self.shareData.postStatus)
                                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        } else {
            let remotePost: RemotePost = {
                let post = RemotePost()
                post.siteID = NSNumber(value: siteID)
                post.status = shareData.postStatus
                post.title = shareData.title
                post.content = shareData.contentBody
                return post
            }()
            let uploadPostOpID = coreDataStack.savePostOperation(remotePost, groupIdentifier: groupIdentifier, with: .inProgress)
            uploadPost(forUploadOpWithObjectID: uploadPostOpID, requestEnqueued: {
                self.tracks.trackExtensionPosted(self.shareData.postStatus)
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
        }
    }
}
