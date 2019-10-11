
class RevisionsTableViewFooter: UIView {
    private var footerLabel: UILabel!


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Public methods

    func setFooterText(_ stringDate: String?) {
        guard let stringDate = stringDate else {
            footerLabel.text = ""
            return
        }

        let text = NSLocalizedString("Post created on %@", comment: "The footer text appears within the footer displaying when the post has been created.")
        footerLabel.text = String.localizedStringWithFormat(text, stringDate)
    }
}


private extension RevisionsTableViewFooter {
    private func setupUI() {
        backgroundColor = .listBackground

        autoresizingMask = .flexibleWidth

        let insets = UIEdgeInsets(top: 5.0, left: 16.0, bottom: 5.0, right: 16.0)
        footerLabel = UILabel(frame: CGRect(x: insets.left,
                                            y: insets.top,
                                            width: frame.width - insets.left - insets.right,
                                            height: frame.height))
        footerLabel.autoresizingMask = .flexibleWidth
        footerLabel.font = UIFont.systemFont(ofSize: 14.0)
        footerLabel.textColor = .neutral(.shade40)
        footerLabel.textAlignment = .center
        footerLabel.numberOfLines = 2

        addSubview(footerLabel)
    }
}
