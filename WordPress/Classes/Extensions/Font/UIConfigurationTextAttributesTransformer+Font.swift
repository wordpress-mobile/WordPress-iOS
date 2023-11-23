
extension UIConfigurationTextAttributesTransformer {

    /// Instance method that sets the font on the ``AttributeContainer``
    static func transformer(with font: UIFont) -> UIConfigurationTextAttributesTransformer {
        return UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
    }

}
