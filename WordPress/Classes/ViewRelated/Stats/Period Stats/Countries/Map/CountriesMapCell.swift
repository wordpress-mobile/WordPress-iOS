import UIKit

class CountriesMapCell: UITableViewCell, NibLoadable {
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

    func configure(with countriesMap: CountriesMap) {
        countriesMapView.setData(countriesMap)
    }
}
