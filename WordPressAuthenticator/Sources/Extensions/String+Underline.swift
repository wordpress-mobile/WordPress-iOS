extension String {
    /// Creates an attributed string from one underlined section that's surrounded by underscores
    ///
    /// - Parameters:
    ///   - color: foreground color to use for the string (optional)
    ///   - underlineColor: foreground color to use for the underlined section (optional)
    /// - Returns: Attributed string
    /// - Note: "this _is_ underlined" would under the "is"
    func underlined(color: UIColor? = nil, underlineColor: UIColor? = nil) -> NSAttributedString {
        let labelParts = self.components(separatedBy: "_")
        let firstPart = labelParts[0]
        let underlinePart = labelParts.indices.contains(1) ? labelParts[1] : ""
        let lastPart = labelParts.indices.contains(2) ? labelParts[2] : ""

        let foregroundColor = color ?? UIColor.black
        let underlineForegroundColor = underlineColor ?? foregroundColor

        let underlinedString = NSMutableAttributedString(string: firstPart, attributes: [.foregroundColor: foregroundColor])
        underlinedString.append(NSAttributedString(string: underlinePart, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: underlineForegroundColor]))
        underlinedString.append(NSAttributedString(string: lastPart, attributes: [.foregroundColor: foregroundColor]))

        return underlinedString
    }
}
