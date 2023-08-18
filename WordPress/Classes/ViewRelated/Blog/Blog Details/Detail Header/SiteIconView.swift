class SiteIconView: UIView {

    private enum Constants {
        static let imageSize: CGFloat = 64
        static let borderRadius: CGFloat = 4
        static let imageRadius: CGFloat = 2
        static let spotlightOffset: CGFloat = 8
    }

    /// Whether or not to show the spotlight animation to illustrate tapping the icon.
    var spotlightIsShown: Bool = true {
        didSet {
            spotlightView.isHidden = !spotlightIsShown
        }
    }

    /// A block to be called when the image button is tapped.
    var tapped: (() -> Void)?

    /// A block to be called when an image is dropped on to the view.
    var dropped: (([UIImage]) -> Void)?

    let imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.imageRadius
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize),
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize)
        ])
        return imageView
    }()

    let activityIndicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .large)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        return indicatorView
    }()

    private var dropInteraction: UIDropInteraction?

    /// Set the menu to be displayed when the button is tapped. The menu replaces
    /// teh default on tap action.
    func setMenu(_ menu: UIMenu, onMenuTriggerd: @escaping () -> Void) {
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.addAction(UIAction { _ in onMenuTriggerd() }, for: .menuActionTriggered)
    }

    private let button: UIButton = {
        let button = UIButton(frame: .zero)
        button.backgroundColor = UIColor.secondaryButtonBackground
        button.clipsToBounds = true
        button.layer.borderColor = UIColor.secondaryButtonBorder.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = Constants.borderRadius
        return button
    }()

    private let spotlightView: UIView = {
        let spotlightView = QuickStartSpotlightView()
        spotlightView.translatesAutoresizingMaskIntoConstraints = false

        spotlightView.isHidden = true
        return spotlightView
    }()

    var allowsDropInteraction: Bool = false {
        didSet {
            if allowsDropInteraction {
                let interaction = UIDropInteraction(delegate: self)
                addInteraction(interaction)
                dropInteraction = interaction
            } else {
                if let dropInteraction = dropInteraction {
                    removeInteraction(dropInteraction)
                }
            }
        }
    }

    init(frame: CGRect, insets: UIEdgeInsets = .zero) {
        super.init(frame: frame)

        button.addSubview(imageView)
        button.pinSubviewToAllEdges(imageView, insets: insets)

        button.addTarget(self, action: #selector(touchedButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(activityIndicator)
        button.pinSubviewAtCenter(activityIndicator)

        button.accessibilityLabel = NSLocalizedString("Site Icon", comment: "Accessibility label for site icon button")
        accessibilityElements = [button]

        addSubview(button)

        addSubview(spotlightView)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: spotlightView.leadingAnchor, constant: Constants.spotlightOffset),
            topAnchor.constraint(equalTo: spotlightView.topAnchor, constant: Constants.spotlightOffset)
        ])

        pinSubviewToAllEdges(button)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func touchedButton() {
        tapped?()
    }

    func removeButtonBorder() {
        button.layer.borderWidth = 0
    }
}

extension SiteIconView: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        imageView.depressSpringAnimation()
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        let isImage = session.canLoadObjects(ofClass: UIImage.self)
        let isSingleImage = session.items.count == 1
        return isImage && isSingleImage
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let location = session.location(in: self)

        let operation: UIDropOperation

        if bounds.contains(location) {
            operation = .copy
        } else {
            operation = .cancel
        }

        return UIDropProposal(operation: operation)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        activityIndicator.startAnimating()

        session.loadObjects(ofClass: UIImage.self) { [weak self] images in
            if let images = images as? [UIImage] {
                self?.dropped?(images)
            }
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, concludeDrop session: UIDropSession) {
        imageView.normalizeSpringAnimation()
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        imageView.normalizeSpringAnimation()
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        imageView.normalizeSpringAnimation()
    }
}
