import FSInteractiveMap
import WordPressShared
import WordPressUI

class CountriesMapView: UIView, NibLoadable {
    private var map = FSInteractiveMapView(frame: CGRect(x: 0, y: 0, width: 335, height: 224))
    private var countries: CountriesMap?
    private lazy var colors: [UIColor] = {
        return mapColors()
    }()

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
            setGradientColors()
        }
    }

    @IBOutlet private var mapContainer: UIView! {
        didSet {
            setBasicMapColors()
            map.loadMap("world-map", withData: [:], colorAxis: colors)
            mapContainer.addSubview(map)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .secondarySystemGroupedBackground
        map.backgroundColor = .secondarySystemGroupedBackground
        colors = mapColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        colors = mapColors()
        setGradientColors()
        setBasicMapColors()
        gradientView.layoutIfNeeded()
        if let countries = countries {
            setData(countries)
        }
    }

    func setData(_ countries: CountriesMap) {
        self.countries = countries
        map.frame = mapContainer.bounds
        map.setData(countries.data, colorAxis: colors)
        minViewsCountLabel.text = String(countries.minViewsCount.abbreviatedString())
        maxViewsCountLabel.text = String(countries.maxViewsCount.abbreviatedString())
    }
}

private extension CountriesMapView {
    func decorate(_ label: UILabel) {
        label.font = WPStyleGuide.fontForTextStyle(.footnote)
        label.textColor = UIAppColor.neutral(.shade70)
    }

    func mapColors() -> [UIColor] {
        if traitCollection.userInterfaceStyle == .dark {
            return [UIAppColor.primary(.shade90), UIAppColor.primary]
        } else {
            return [UIAppColor.primary(.shade5), UIAppColor.primary]
        }
    }

    func setGradientColors() {
        gradientView.fromColor = colors.first ?? .white
        gradientView.toColor = colors.last ?? .black
    }

    func setBasicMapColors() {
        map.strokeColor = .secondarySystemGroupedBackground
        map.fillColor = WPStyleGuide.Stats.mapBackground
    }
}
