import UIKit

class CountriesMapCell: UITableViewCell, NibLoadable {
    private let countriesMapView = CountriesMapView.loadFromNib()

    @IBOutlet private var countriesMapContainer: UIStackView! {
        didSet {
            countriesMapContainer.addArrangedSubview(countriesMapView)
        }
    }

    func configure(with countriesMap: CountriesMap) {
        countriesMapView.setData(countriesMap)
    }
}
