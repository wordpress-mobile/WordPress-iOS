import Foundation


extension NSString {
    /// Returns the string's hostname, if any
    ///
    @objc public func hostname() -> String? {
        return URLComponents(string: self as String)?.host
    }

    /// Splits the lines contained in the current string, and returns the unique values in a NSSet instance
    ///
    @objc public func uniqueStringComponentsSeparatedByNewline() -> NSSet {
        let components = self.components(separatedBy: CharacterSet.newlines)

        let filtered = components.filter { !$0.isEmpty }

        let uniqueSet = NSMutableSet()
        uniqueSet.addObjects(from: filtered)

        return uniqueSet
    }

    /// Validates the current string. Returns true if passes validation
    ///
    @objc public func isValidEmail() -> Bool {
        let emailRegex = "^.+@.+$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        return emailTest.evaluate(with: self)
    }
}
