import FSInteractiveMap

class CountriesMapView: UIView, NibLoadable {
    private var map = FSInteractiveMapView(frame: CGRect(x: 0, y: 0, width: 335, height: 224))

    @IBOutlet private var mapContainer: UIView! {
        didSet {
            map.strokeColor = .white
            map.loadMap("world-map", withData: [:], colorAxis: [UIColor.yellow, UIColor.red])
            mapContainer.addSubview(map)
        }
    }

    func setData() {
        map.frame = mapContainer.bounds
        map.setData([:], colorAxis: [UIColor.yellow, UIColor.red])
    }
}
