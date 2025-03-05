import UIKit
import SafariServices

// […]
final class ReaderReadMoreView: UIView, UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    private let textView = UITextView.makeLabel()
    private let infoIconView = UIImageView(image: UIImage(systemName: "info.circle"))
    private var postURL: URL?

    init(post: ReaderPost) {
        super.init(frame: .zero)

        let gradientMaskView = GradientAlphaMaskView()
        addSubview(gradientMaskView)
        gradientMaskView.pinEdges()

        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        visualEffectView.layer.cornerRadius = 8
        visualEffectView.layer.masksToBounds = true

        addSubview(visualEffectView)
        visualEffectView.pinEdges(insets: UIEdgeInsets(top: 80, left: 0, bottom: 16, right: 0))

        textView.adjustsFontForContentSizeCategory = true

        let string = NSMutableAttributedString(string: Strings.viewFullPost, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body)
        ])
        if let postURL = post.permaLink.flatMap(URL.init) {
            string.addAttribute(.link, value: postURL, range: NSRange(location: 0, length: string.length))
            self.postURL = postURL
        }
        textView.attributedText = string

        infoIconView.tintColor = .secondaryLabel
        infoIconView.isUserInteractionEnabled = true
        NSLayoutConstraint.activate([
            infoIconView.widthAnchor.constraint(equalToConstant: 20),
            infoIconView.heightAnchor.constraint(equalToConstant: 20)
        ])
        infoIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showInfoTapped)))

        let stackView = UIStackView(alignment: .center, spacing: 16, [textView, infoIconView])

        visualEffectView.contentView.addSubview(stackView)
        stackView.pinEdges(insets: UIEdgeInsets(.all, 16))

        visualEffectView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewMoreTapped)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func viewMoreTapped() {
        guard let postURL else {
            return
        }
        let safariVC = SFSafariViewController(url: postURL)
        UIViewController.topViewController?.present(safariVC, animated: true)
    }

    @objc private func showInfoTapped() {
        let popoverVC = UIViewController()

        let detailsLabel = UILabel()
        detailsLabel.font = .preferredFont(forTextStyle: .footnote)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.text = Strings.details
        detailsLabel.numberOfLines = 0
        let preferredWidth: CGFloat = 320
        detailsLabel.widthAnchor.constraint(lessThanOrEqualToConstant: preferredWidth).isActive = true

        popoverVC.view.backgroundColor = .systemBackground
        popoverVC.view.addSubview(detailsLabel)
        detailsLabel.pinEdges(insets: UIEdgeInsets(.all, 16))
        popoverVC.preferredContentSize = popoverVC.view.systemLayoutSizeFitting(CGSize(width: preferredWidth, height: 1200))

        popoverVC.modalPresentationStyle = .popover
        popoverVC.popoverPresentationController?.delegate = self
        popoverVC.popoverPresentationController?.sourceView = infoIconView
        UIViewController.topViewController?.present(popoverVC, animated: true)
    }

    // MARK: UIAdaptivePresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none // Force popover on iPhone
    }
}

private final class GradientAlphaMaskView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        gradientLayer.frame = bounds
        gradientLayer.locations = [0.0, 1.0]
        refreshColors()

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.5)

        self.layer.addSublayer(gradientLayer)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        refreshColors()
    }

    private func refreshColors() {
        gradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0).cgColor, UIColor.systemBackground.cgColor]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
    }
}

private enum Strings {
    static let viewFullPost = NSLocalizedString("reader.postDetails.viewFullPost", value: "View full post", comment: "Button title")
    static let blog = NSLocalizedString("reader.postDetails.blog", value: "blog", comment: "Reader post details view placeholder when blog name not avail")
    static let details = NSLocalizedString("reader.postDetails.viewModeDescription", value: "The owner of this site only allows us to show a brief summary of their content. To view the full post, you'll have to visit their site.", comment: "Reader post details view")
}
