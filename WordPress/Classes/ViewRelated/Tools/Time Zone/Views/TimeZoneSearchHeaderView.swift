import UIKit

final class TimeZoneSearchHeaderView: UIView {

    @IBOutlet private weak var searchWrapperView: SearchWrapperView!

    @IBOutlet private weak var searchWrapperViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var suggestionLabel: UILabel!

    @IBOutlet private weak var suggestionButton: UIButton!

    /// Callback called when the button is tapped
    var tapped: (() -> Void)?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    class func makeFromNib(searchBar: UISearchBar, timezone: String) -> TimeZoneSearchHeaderView? {
        guard let view = Bundle.main.loadNibNamed(Constants.nibIdentifier,
                                        owner: self,
                                        options: nil)?.first as? TimeZoneSearchHeaderView else {
            assertionFailure("Failed to load view from nib named \(Constants.nibIdentifier)")
            return nil
        }

        view.searchWrapperView.addSubview(searchBar)
        view.searchWrapperViewHeightConstraint.constant = searchBar.frame.height

        view.suggestionLabel.text = Localization.suggestion

        view.suggestionButton.setTitle(timezone, for: .normal)
        view.suggestionButton.addTarget(view, action: #selector(buttonTapped), for: .touchUpInside)

        return view
    }

    @objc private func buttonTapped() {
        tapped?()
    }
}

// MARK: - Constants

private extension TimeZoneSearchHeaderView {

    enum Constants {
        static let nibIdentifier = "TimeZoneSearchHeaderView"
    }

    enum Localization {
        static let suggestion = NSLocalizedString("Suggestion:",
                                                  comment: "Label displayed to the user left of the time zone suggestion button")
    }
}
