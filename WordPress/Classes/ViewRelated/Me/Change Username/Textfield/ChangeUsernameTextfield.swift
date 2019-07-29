class ChangeUsernameTextfield: UIView, NibLoadable {
    override func awakeFromNib() {
        super.awakeFromNib()

        addTopBorder(withColor: .neutral(shade: .shade10))
        addBottomBorder(withColor: .neutral(shade: .shade10))
    }
}
