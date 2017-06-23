import UIKit

extension FancyAlertViewController {
    static func aztecAnnouncementController() -> FancyAlertViewController {
        typealias Button = FancyAlertViewController.Config.ButtonConfig

        let defaultButton = Button("Try It", { controller in
            controller.configuration = aztecAnnouncementSuccessConfig
        })

        let cancelButton = Button("Now Now", { controller in
            controller.dismiss(animated: true, completion: nil)
        })

        let moreInfoButton = Button("What's new?", { _ in })

        let titleAccessoryButton = Button("Beta", { _ in })

        let image = UIImage(named: "wp-illustration-hand-write")

        let config = FancyAlertViewController.Config(titleText: "Try the New Editor",
                                                     bodyText: "The WordPress app now includes a beautiful new editor. Try it out by creating a new post!",
                                                     headerImage: image,
                                                     defaultButton: defaultButton, cancelButton: cancelButton, moreInfoButton: moreInfoButton, titleAccessoryButton: titleAccessoryButton)

        return FancyAlertViewController.controllerWithConfiguration(configuration: config)
    }

    private static let aztecAnnouncementSuccessConfig: FancyAlertViewController.Config = {
        typealias Button = FancyAlertViewController.Config.ButtonConfig

        let moreInfoButton = Button("Me > App Settings", { _ in })

        let titleAccessoryButton = Button("Beta", { _ in })

        return FancyAlertViewController.Config(titleText: "New Editor Enabled!",
                                               bodyText: "Thanks for trying it out! You can switch editor modes at any time in",
                                               headerImage: UIImage(named: "wp-illustration-thank-you"),
                                               defaultButton: nil, cancelButton: nil, moreInfoButton: moreInfoButton, titleAccessoryButton: titleAccessoryButton)
    }()
}
