import UIKit

extension NSNotification.Name {
    static let jetpackPluginInstallCompleted = NSNotification.Name(rawValue: "JetpackPluginInstallCompleted")
    static let jetpackPluginInstallCanceled = NSNotification.Name(rawValue: "JetpackPluginInstallCanceled")
}

final class JetpackInstallCoordinator {
    private let promptType: JetpackLoginPromptType
    private let blog: Blog
    private let completionBlock: (() -> Void)?

    private weak var navigationController: UINavigationController?

    init(
        blog: Blog,
        promptType: JetpackLoginPromptType,
        navigationController: UINavigationController?,
        completionBlock: (() -> Void)?
    ) {
        self.blog = blog
        self.promptType = promptType
        self.navigationController = navigationController
        self.completionBlock = completionBlock
    }

    func openJetpackRemoteInstall() {
        trackStat(.selectedInstallJetpack)
        let controller = JetpackRemoteInstallViewController(blog: blog,
                                                            delegate: self,
                                                            promptType: promptType)

        // If we're already in a nav controller then push don't present again
        guard promptType == .installPrompt else {
            let navController = UINavigationController(rootViewController: controller)
            navController.modalPresentationStyle = .fullScreen
            navigationController?.present(navController, animated: true)
            return
        }

        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - Tracking

private extension JetpackInstallCoordinator {
    func trackStat(_ stat: WPAnalyticsStat, blog: Blog? = nil) {
        var properties = [String: String]()
        switch promptType {
        case .stats:
            properties["source"] = "stats"
        case .notifications:
            properties["source"] = "notifications"

        case .installPrompt:
            properties["source"] = "install_prompt"
        }

        if let blog = blog {
            WPAppAnalytics.track(stat, withProperties: properties, with: blog)
        } else {
            WPAnalytics.track(stat, withProperties: properties)
        }
    }
}

// MARK: - Browser

private extension JetpackInstallCoordinator {
    private func openInstallJetpackURL() {
        trackStat(.selectedInstallJetpack)
        let controller = JetpackConnectionWebViewController(blog: blog)
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller)
        navigationController?.present(navController, animated: true)
    }
}

// MARK: - Handling Delegate

extension JetpackInstallCoordinator: JetpackConnectionWebDelegate {
    func jetpackConnectionCompleted() {
        jetpackIsCompleted()
    }

    func jetpackConnectionCanceled() {
        jetpackIsCanceled()
    }
}

extension JetpackInstallCoordinator: JetpackRemoteInstallDelegate {
    func jetpackRemoteInstallCanceled() {
        jetpackIsCanceled()
    }

    func jetpackRemoteInstallCompleted() {
        jetpackIsCompleted()
    }

    func jetpackRemoteInstallWebviewFallback() {
        trackStat(.installJetpackRemoteStartManualFlow)
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.openInstallJetpackURL()
        }
    }
}

private extension JetpackInstallCoordinator {
    func jetpackIsCompleted() {
        trackStat(.installJetpackCompleted)
        trackStat(.signedInToJetpack, blog: blog)

        NotificationCenter.default.post(name: .jetpackPluginInstallCompleted, object: nil)

        navigationController?.dismiss(animated: true, completion: completionBlock)
    }

    func jetpackIsCanceled() {
        trackStat(.installJetpackCanceled)

        NotificationCenter.default.post(name: .jetpackPluginInstallCanceled, object: nil)

        navigationController?.dismiss(animated: true, completion: completionBlock)
    }
}
