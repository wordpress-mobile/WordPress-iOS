import Foundation


extension NSString
{
    /**
     *  @details Splits the words contained in the current string, and returns its
     *           unique values in a NSSet instance.
     */
    public func uniqueStringComponentsSeparatedByWhitespace() -> NSSet {
        let components = componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        let uniqueSet = NSMutableSet()
        uniqueSet.addObjectsFromArray(components)
        
        return uniqueSet
    }
}
