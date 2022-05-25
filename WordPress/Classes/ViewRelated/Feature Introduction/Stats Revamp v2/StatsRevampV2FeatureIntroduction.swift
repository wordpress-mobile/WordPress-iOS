import UIKit

class StatsRevampV2FeatureIntroduction: FeatureIntroductionViewController {

    var presenter: StatsRevampV2IntroductionPresenter?

    init() {
        let featureDescriptionView = StatsRevampV2FeatureDescriptionView.loadFromNib()
        featureDescriptionView.translatesAutoresizingMaskIntoConstraints = false

        super.init(headerTitle: HeaderStrings.title, headerSubtitle: "", headerImage: nil, featureDescriptionView: featureDescriptionView, primaryButtonTitle: ButtonStrings.showMe, secondaryButtonTitle: nil)

        featureIntroductionDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StatsRevampV2FeatureIntroduction: FeatureIntroductionDelegate {
    func primaryActionSelected() {
        presenter?.primaryButtonSelected()
    }
}

private extension StatsRevampV2FeatureIntroduction {

    enum ButtonStrings {
        static let showMe = NSLocalizedString("Try it now", comment: "Button title to take user to the new Stats Insights screen.")
    }

    enum HeaderStrings {
        static let title = NSLocalizedString("Insights update", comment: "Title displayed on the feature introduction view that announces the updated Stats Insight screen.")
    }
}
