import UIKit

final class SiteDetailsSiteIconView: UIView {

    private enum Constants {
        static var imageSize: CGFloat { SiteIconViewModel.Size.regular.width }
    }

    /// A block to be called when the image button is tapped.
    var tapped: (() -> Void)?

    /// A block to be called when an image is dropped on to the view.
    var dropped: (([UIImage]) -> Void)?

    let imageView = SiteIconHostingView()

    private let imageViewSizeConstraints: [NSLayoutConstraint]

    func setImageViewSize(_ size: CGFloat) {
        for constraint in imageViewSizeConstraints {
            constraint.constant = size
        }
    }

    let activityIndicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        return indicatorView
    }()

    private var dropInteraction: UIDropInteraction?

    /// Set the menu to be displayed when the button is tapped. The menu replaces
    /// teh default on tap action.
    func setMenu(_ menu: UIMenu, onMenuTriggered: @escaping () -> Void) {
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.addAction(UIAction { _ in onMenuTriggered() }, for: .menuActionTriggered)
    }

    private let button: UIButton = {
        let button = UIButton(frame: .zero)
        button.backgroundColor = UIColor.clear
        button.clipsToBounds = true
        return button
    }()

    var allowsDropInteraction: Bool = false {
        didSet {
            if allowsDropInteraction {
                let interaction = UIDropInteraction(delegate: self)
                addInteraction(interaction)
                dropInteraction = interaction
            } else {
                if let dropInteraction {
                    removeInteraction(dropInteraction)
                }
            }
        }
    }

    init(frame: CGRect, insets: UIEdgeInsets = .zero) {
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageViewSizeConstraints = [
            imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize),
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize)
        ]
        NSLayoutConstraint.activate(imageViewSizeConstraints)

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

extension SiteDetailsSiteIconView: UIDropInteractionDelegate {
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
