import UIKit
import SVProgressHUD
import WordPressData
import WordPressKit
import WordPressShared

/// Presents the starter design picker for an existing site and applies the chosen design.
@MainActor
final class StarterDesignPickerCoordinator {
    private let applier: StarterDesignApplier
    private let onApplied: () -> Void
    private weak var navigationController: UINavigationController?
    private var isApplying = false

    private init(applier: StarterDesignApplier, onApplied: @escaping () -> Void) {
        self.applier = applier
        self.onApplied = onApplied
    }

    /// - Parameter onApplied: Called after a design is applied and the picker is dismissed.
    static func start(for blog: Blog, from presenter: UIViewController, onApplied: @escaping () -> Void) {
        guard let api = blog.wordPressComRestApi else {
            return wpAssertionFailure("The design card is only shown for WordPress.com sites")
        }

        let coordinator = StarterDesignPickerCoordinator(
            applier: StarterDesignApplier(blog: blog, api: api),
            onApplied: onApplied
        )
        let loader = StarterDesignSectionLoader(api: api, siteTitle: blog.settings?.name, language: language(of: blog))
        // The picker's selection closure keeps the coordinator alive for as long as the picker exists.
        let picker = SiteDesignContentCollectionViewController(
            context: .dashboard,
            vertical: { nil },
            loadAssembler: loader.buildAssembler(scale:completion:)
        ) { design in
            guard let design else { return }
            coordinator.apply(design)
        }

        let navigationController = UINavigationController(rootViewController: picker)
        coordinator.navigationController = navigationController
        presenter.present(navigationController, animated: true)
    }

    private func apply(_ design: RemoteSiteDesign) {
        // The preview dismisses itself before calling back, so the picker is interactive again here, and the HUD
        // does not block touches. A second design chosen now could activate after, and overwrite, this one.
        guard !isApplying else {
            return
        }
        isApplying = true
        setPickerInteractionEnabled(false)
        SVProgressHUD.show()

        Task {
            do {
                try await applier.apply(design)
                await SVProgressHUD.dismiss()
                navigationController?.dismiss(animated: true)
                Notice(title: Strings.applied).post()
                onApplied()
            } catch {
                await SVProgressHUD.dismiss()
                setPickerInteractionEnabled(true)
                Notice(title: Strings.failed, message: error.localizedDescription, feedbackType: .error).post()
            }
            isApplying = false
        }
    }

    private func setPickerInteractionEnabled(_ isEnabled: Bool) {
        navigationController?.view.isUserInteractionEnabled = isEnabled
        navigationController?.isModalInPresentation = !isEnabled
    }

    private static func language(of blog: Blog) -> String {
        let database = WordPressComLanguageDatabase.shared
        if let languageID = blog.settings?.languageID.intValue, let language = database.find(id: languageID) {
            return language.slug
        }
        return database.deviceLanguage.slug
    }

    private enum Strings {
        static let applied = NSLocalizedString(
            "dashboard.designCard.applied",
            value: "Design applied",
            comment: "Notice shown after a design chosen from the Dashboard design card is applied to the site."
        )
        static let failed = NSLocalizedString(
            "dashboard.designCard.applyFailed",
            value: "Couldn't apply the design",
            comment: "Notice shown when applying a design chosen from the Dashboard design card fails."
        )
    }
}
