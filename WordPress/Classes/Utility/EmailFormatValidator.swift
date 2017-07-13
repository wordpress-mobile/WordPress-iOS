import Foundation

/// Test a string to see if it resembles an email address.  The checks in this
/// class are based on those in wp-includes/formatting.php `is_email`.
///
open class EmailFormatValidator {

    /// Validate the specified string.
    ///
    public class func validate(string: String) -> Bool {
        let str = string as NSString
        // Test for the minimum length the email can be
        if !isMinEmailLength(str) {
            return false
        }

        // Test for an @ character after the first position
        if !hasAtSign(str) {
            return false
        }

        // Split out the local and domain parts
        let arr = str.components(separatedBy: "@")
        if arr.count != 2 {
            return false
        }

        let local = arr[0] as NSString
        let domain = arr[1] as NSString

        // Local part

        // Test for invalid characters
        if containsLocalPartForbiddenCharacters(local) {
            return false
        }

        // Domain part

        // Test for sequences of periods
        if containsPeriodSequence(domain) {
            return false
        }

        // Test for whitespace
        if containsWhitespace(domain) {
            return false
        }

        // Test for leading/trailing periods
        if containsLeadingOrTrailingPeriod(domain) {
            return false
        }

        // Check for unallowed characters
        if containsDomainPartForbiddenCharacters(domain) {
            return false
        }

        // Split the domain into parts. Assume a minimum of two parts.
        if !resemblesHostname(domain) {
            return false
        }

        return true
    }


    /// Checks that the supplied string is at least the expected minimum email length.
    ///
    private class func isMinEmailLength(_ str: NSString) -> Bool {
        return str.length >= 6
    }


    /// Checks if the supplied string contains an @ sign that is not the first character.
    ///
    private class func hasAtSign(_ str: NSString) -> Bool {
        return str.range(of: "@").location > 0
    }


    /// Test that the string contains characters permitted in the local part of an email address.
    ///
    private class func containsLocalPartForbiddenCharacters(_ str: NSString) -> Bool {
        // match for allowed characters
        let regex = "^[a-zA-Z0-9!#$%&'*+\\/=?^_`{|}~\\.-]+$"
        let match = NSPredicate(format: "SELF MATCHES %@", regex)
        return !match.evaluate(with: str)
    }


    /// Check if the string contains more than one period in a row.
    ///
    private class func containsPeriodSequence(_ str: NSString) -> Bool {
        return str.contains("..")
    }


    /// Check if the string contains any whitespace or newline characters.
    ///
    private class func containsWhitespace(_ str: NSString) -> Bool {
        return str.rangeOfCharacter(from: .whitespacesAndNewlines).location != NSNotFound
    }


    /// Check if the string contains any leading or trailing periods.
    ///
    private class func containsLeadingOrTrailingPeriod(_ str: NSString) -> Bool {
        return str.hasPrefix(".") || str.hasSuffix(".")
    }


    /// Check if the string contains characters forbidden in the domain part of an email address.
    ///
    private class func containsDomainPartForbiddenCharacters(_ str: NSString) -> Bool {
        // Match for allowed characters
        // If the match evaluates to true, then the string contains at least one forbidden character
        let regex = "^[a-zA-Z0-9-.]+$"
        let match = NSPredicate(format: "SELF MATCHES %@", regex)
        return !match.evaluate(with: str)
    }


    /// Check if the supplied string resembles a host name.
    ///
    private class func resemblesHostname(_ str: NSString) -> Bool {
        // A host name should have two or more parts
        let parts = str.components(separatedBy: ".")
        return parts.count > 1
    }
}
