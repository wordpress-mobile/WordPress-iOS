import UIKit

// TODO: add description

class BloggingPromptsFeatureIntroduction: FeatureIntroductionViewController {

    class func navigationController() -> UINavigationController {
        let controller = BloggingPromptsFeatureIntroduction()
        let navController = UINavigationController(rootViewController: controller)
        return navController
    }

    init() {
        super.init(headerTitle: Strings.headerTitle,
                   headerSubtitle: Strings.headerSubtitle,
                   // TODO: provide lightbulb image
                   headerImage: nil,
                   // TODO: provide feature description view
                   featureDescriptionView: UIView(),
                   primaryButtonTitle: Strings.primaryButtonTitle,
                   secondaryButtonTitle: Strings.secondaryButtonTitle)

        featureIntroductionDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension BloggingPromptsFeatureIntroduction: FeatureIntroductionDelegate {

    func primaryActionSelected() {
        // TODO: show site selector/draft post
    }

    func secondaryActionSelected() {
        // TODO: show site selector/Blogging Reminders
    }

}


private extension BloggingPromptsFeatureIntroduction {

    enum Strings {
        static let headerTitle: String = NSLocalizedString("Introducing Prompts", comment: "Title displayed on the feature introduction view.")
        static let headerSubtitle: String = NSLocalizedString("The best way to become a better writer is to build a writing habit and share with others - that’s where Prompts come in!", comment: "Subtitle displayed on the feature introduction view.")
        static let primaryButtonTitle: String = NSLocalizedString("Try it now", comment: "Primary button title on the feature introduction view.")
        static let secondaryButtonTitle: String = NSLocalizedString("Remind me", comment: "Secondary button title on the feature introduction view.")
    }

}
