import FSInteractiveMap
import WordPressShared

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
            gradientView.fromColor = colors.first ?? .white
            gradientView.toColor = colors.last ?? .black
        }
    }

    @IBOutlet private var mapContainer: UIView! {
        didSet {
            map.strokeColor = .listForeground
            map.fillColor = WPStyleGuide.Stats.mapBackground
            map.loadMap("world-map", withData: [:], colorAxis: colors)
            mapContainer.addSubview(map)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .listForeground
        map.backgroundColor = .listForeground
        colors = mapColors()
    }

    func setData(_ countries: CountriesMap) {
        self.countries = countries
        map.frame = mapContainer.bounds
        map.setData(countries.data, colorAxis: colors)
        minViewsCountLabel.text = String(countries.minViewsCount.abbreviatedString())
        maxViewsCountLabel.text = String(countries.maxViewsCount.abbreviatedString())
    }

    private func decorate(_ label: UILabel) {
        label.font = WPStyleGuide.fontForTextStyle(.footnote)
        label.textColor = .neutral(.shade70)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        colors = mapColors()
        if let countries = countries {
            setData(countries)
        }
    }

    private func mapColors() -> [UIColor] {
        #if XCODE11
        if #available(iOS 13, *) {
            if traitCollection.userInterfaceStyle == .dark {
                return [.accent(.shade90), .accent]
            }
        }
        #endif
        return [.accent(.shade5), .accent]
    }
}
