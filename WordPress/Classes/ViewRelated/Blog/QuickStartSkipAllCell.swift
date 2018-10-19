class QuickStartSkipAllCell: UITableViewCell {
    @IBOutlet var skipAllButton: UIButton?
    var onTap: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

//        topLabel?.text = NSLocalizedString("Congrats on finishing Quick Start  🎉", comment: "Headline shown to users when they complete all Quick Start items")
        let buttonTitle = NSLocalizedString("Skip All", comment: "Label for button that will allow the user to skip all items in the Quick Start checklist")
        skipAllButton?.setTitle(buttonTitle, for: .normal)
    }

    @IBAction func tapped() {
        onTap?()
    }

    static let reuseIdentifier = "QuickStartSkipAllCell"
}
