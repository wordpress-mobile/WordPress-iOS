import Foundation


extension NSString
{
    /**
     *  @details Splits the lines contained in the current string, and returns its unique values in a NSSet instance.
     */
    public func uniqueStringComponentsSeparatedByNewline() -> NSSet {
        let components = componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        let uniqueSet = NSMutableSet()
        uniqueSet.addObjectsFromArray(components)
        
        return uniqueSet
    }
}
