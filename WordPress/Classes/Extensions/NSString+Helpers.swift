import Foundation


extension NSString
{
    /// Returns the string's hostname, if any
    ///
    public func hostname() -> String? {
        return NSURLComponents(string: self as String)?.host
    }

    /// Splits the lines contained in the current string, and returns the unique values in a NSSet instance
    ///
    public func uniqueStringComponentsSeparatedByNewline() -> NSSet {
        let components = componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())

        let filtered = components.filter { !$0.isEmpty }

        let uniqueSet = NSMutableSet()
        uniqueSet.addObjectsFromArray(filtered)

        return uniqueSet
    }

    /// Validates the current string. Returns true if passes validation
    ///
    public func isValidEmail() -> Bool {
        let emailRegex = "^.+@.+$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        return emailTest.evaluateWithObject(self)
    }
}
