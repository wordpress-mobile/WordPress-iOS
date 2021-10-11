extension UIFont {
    /// Returns a UIFont instance with the italic trait applied.
    func italic() -> UIFont {
        return withSymbolicTraits(.traitItalic)
    }

    /// Returns a UIFont instance with the bold trait applied.
    func bold() -> UIFont {
        return withWeight(.bold)
    }

    /// Returns a UIFont instance with the semibold trait applied.
    func semibold() -> UIFont {
        return withWeight(.semibold)
    }

    private func withSymbolicTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: 0)
    }

    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])

        return UIFont(descriptor: descriptor, size: 0)
    }
}
