import UIKit

class CountriesMapCell: UITableViewCell, NibLoadable, Accessible {
    private let countriesMapView = CountriesMapView.loadFromNib()
    private typealias Style = WPStyleGuide.Stats

    @IBOutlet private var separatorLine: UIView! {
        didSet {
            Style.configureViewAsSeparator(separatorLine)
        }
    }
    @IBOutlet private var countriesMapContainer: UIStackView! {
        didSet {
            countriesMapContainer.addArrangedSubview(countriesMapView)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        prepareForVoiceOver()
    }

    func configure(with countriesMap: CountriesMap) {
        countriesMapView.setData(countriesMap)
    }

    func prepareForVoiceOver() {
        accessibilityLabel = NSLocalizedString("World map showing views by country.", comment: "Accessibility label for the Stats' world map.")
    }
}
