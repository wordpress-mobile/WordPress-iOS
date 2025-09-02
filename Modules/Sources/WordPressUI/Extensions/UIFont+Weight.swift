import UIKit

extension UIFont {
    /// Returns a UIFont instance with the italic trait applied.
    func italic() -> UIFont {
        withSymbolicTraits(.traitItalic)
    }

    /// Returns a UIFont instance with the bold trait applied.
    public func bold() -> UIFont {
        withWeight(.bold)
    }

    /// Returns a UIFont instance with the semibold trait applied.
    public func semibold() -> UIFont {
        withWeight(.semibold)
    }

    private func withSymbolicTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }

    public func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: 0)
    }
}
