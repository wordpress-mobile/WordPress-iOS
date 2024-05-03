
class ReaderTagFooterView: UICollectionReusableView {

    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var arrowButton: UIButton!
    @IBOutlet private weak var moreLabel: UILabel!

    private var onTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyles()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        addGestureRecognizer(tapGesture)
    }

    func configure(with slug: String, onTapped: @escaping () -> Void) {
        moreLabel.setText(String(format: Constants.moreText, slug))
        self.onTapped = onTapped
    }

    @objc func onViewTapped() {
        onTapped?()
    }

    @IBAction func onArrowButtonTapped(_ sender: Any) {
        onTapped?()
    }

    private func setupStyles() {
        moreLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        arrowButton.configuration?.background.backgroundColor = UIColor(light: .secondarySystemBackground,
                                                                        dark: .tertiarySystemBackground)
    }

    private struct Constants {
        static let moreText = NSLocalizedString("reader.tags.footer.more",
                                                value: "More from %1$@",
                                                comment: "Label for an action to open more content from a specified Reader tag. %1$@ is the Reader tag.")
    }

}
