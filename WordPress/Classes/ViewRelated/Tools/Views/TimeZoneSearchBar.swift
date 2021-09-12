import UIKit

final class TimeZoneSearchBar: UIView {

    @IBOutlet private weak var searchWrapperView: SearchWrapperView!

    @IBOutlet private weak var searchWrapperViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var suggestionLabel: UILabel!

    @IBOutlet private weak var suggestionButton: UIButton!

    /// Callback called when the button is tapped
    var tapped: (() -> Void)?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> TimeZoneSearchBar {
        return Bundle.main.loadNibNamed(Constants.nibIdentifier,
                                        owner: self,
                                        options: nil)?.first as! TimeZoneSearchBar
    }

    // MARK: - Convenience Initializers
    
    override func awakeFromNib() {
        super.awakeFromNib()

        suggestionLabel.text = Localization.suggestion
        suggestionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        tapped?()
    }

    func configureSearchWrapperView(searchBar: UISearchBar) {
        searchWrapperView.addSubview(searchBar)
        searchWrapperViewHeightConstraint.constant = searchBar.frame.height
    }

    func configureDefaultTimeZone(timezone: String) {
        suggestionButton.setTitle(timezone, for: .normal)
    }
}


// MARK: - Constants

private extension TimeZoneSearchBar {

    enum Constants {
        static let nibIdentifier = "TimeZoneSearchBar"
    }

    enum Localization {
        static let suggestion = NSLocalizedString("Suggestion:",
                                                  comment: "Label displayed to the user left of the time zone suggestion button")
    }
}
