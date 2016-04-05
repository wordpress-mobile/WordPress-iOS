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
        // From http://stackoverflow.com/a/3638271/1379066
        let emailRegex = ".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailTest.evaluateWithObject(self)
    }
}
