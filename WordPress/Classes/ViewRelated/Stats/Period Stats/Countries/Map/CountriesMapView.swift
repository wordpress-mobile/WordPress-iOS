import FSInteractiveMap
import WordPressShared

class CountriesMapView: UIView, NibLoadable {
    private var map = FSInteractiveMapView(frame: CGRect(x: 0, y: 0, width: 335, height: 224))
    private let colors: [UIColor] = [.accent(shade: .shade5), .accent]
    @IBOutlet private var minViewsCountLabel: UILabel! {
        didSet {
            decorate(minViewsCountLabel)
        }
    }
    @IBOutlet private var maxViewsCountLabel: UILabel! {
        didSet {
            decorate(maxViewsCountLabel)
        }
    }
    @IBOutlet private var gradientView: GradientView! {
        didSet {
            gradientView.fromColor = colors.first ?? .white
            gradientView.toColor = colors.last ?? .black
        }
    }

    @IBOutlet private var mapContainer: UIView! {
        didSet {
            map.strokeColor = .white
            map.fillColor = .neutral(shade: .shade10)
            map.loadMap("world-map", withData: [:], colorAxis: colors)
            mapContainer.addSubview(map)
        }
    }

    func setData(_ countries: CountriesMap) {
        map.frame = mapContainer.bounds
        map.setData(countries.data, colorAxis: colors)
        minViewsCountLabel.text = String(countries.minViewsCount.abbreviatedString())
        maxViewsCountLabel.text = String(countries.maxViewsCount.abbreviatedString())
    }

    private func decorate(_ label: UILabel) {
        label.font = WPStyleGuide.fontForTextStyle(.footnote)
        label.textColor = .neutral(shade: .shade70)
    }
}
