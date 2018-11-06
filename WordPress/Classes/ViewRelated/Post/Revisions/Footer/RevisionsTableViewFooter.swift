
class RevisionsTableViewFooter: UIView {
    @IBOutlet private var footerLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = WPStyleGuide.greyLighten30()
        footerLabel.textColor = WPStyleGuide.greyDarken10()
    }


    // MARK: Public methods

    func setFooterText(_ stringDate: String?) {
        guard let stringDate = stringDate else {
            footerLabel.text = ""
            return
        }

        let text = NSLocalizedString("Post Created on %@", comment: "The footer text appears within the footer displaying when the post has been created.")
        footerLabel.text = String.localizedStringWithFormat(text, stringDate)
    }
}
