import Foundation


extension BlogSettings
{
    /**
     *  @enum    BlogSettings.SortOrder
     *  @brief   Enumerates all of the valid Sorting Orders
     */
    public enum SortOrder : Int {
        case Ascending  = 0
        case Descending = 1
        
        var description : String {
            return SortOrder.DescriptionMap[self.rawValue]!
        }
        
        public static var SortTitles : [String] {
            return DescriptionMap.keys.map { DescriptionMap[$0]! }
        }
        
        public static var SortValues : [Int] {
            return DescriptionMap.keys.sort()
        }
        
        public static var DescriptionMap = [
            Ascending.rawValue   : NSLocalizedString("Oldest First", comment: "Sort Order"),
            Descending.rawValue  : NSLocalizedString("Newest First", comment: "Sort Order")
        ]
    }

    
    
    public struct Threading
    {
        public static let DepthDisabled = 0
        
        public static let DepthMinimum  = 2
        
        public static let DepthMaximum  = 10
        
        public static var DepthTitles : [String] {
            return DepthValues.map { DepthMap[$0]! }
        }
        
        public static var DepthValues : [Int] {
            return DepthMap.keys.sort()
        }
        
        public static var DepthMap : [Int : String] {
            let posfixText = NSLocalizedString(" levels", comment: "Threading Levels. A numeric value will be prepended")
            var optionsMap = [Int : String]()
            
            optionsMap[DepthDisabled] = NSLocalizedString("Disabled", comment: "")
            
            for currentLevel in DepthMinimum...DepthMaximum {
                let level = NSNumberFormatter.localizedStringFromNumber(currentLevel, numberStyle: .SpellOutStyle)
                optionsMap[currentLevel] = level.capitalizedString + posfixText
            }
            
            return optionsMap
        }
    }
    
    
    
    public enum AutomaticallyApprove : Int {
        case Disabled       = 0
        case FromKnownUsers = 1
        case Everything     = 2
        
        var description : String {
            return AutomaticallyApprove.OptionsMap[self.rawValue]!
        }
        
        public static var OptionTitles : [String] {
            return OptionValues.map { OptionsMap[$0]! }
        }

        public static var OptionHints : [String] {
            return OptionValues.map { OptionsHints[$0]! }
        }
        
        public static var OptionValues : [Int] {
            return OptionsMap.keys.sort()
        }
        
        private static let OptionsMap = [
            Disabled.rawValue        : NSLocalizedString("No comments", comment: ""),
            FromKnownUsers.rawValue  : NSLocalizedString("Known user's comments", comment: ""),
            Everything.rawValue      : NSLocalizedString("All comments", comment: "")
        ]
        
        private static let OptionsHints = [
            Disabled.rawValue        : NSLocalizedString("Require manual approval for everyone's comments.", comment: ""),
            FromKnownUsers.rawValue  : NSLocalizedString("Automatically approve if the user has a previously approved comment.", comment: ""),
            Everything.rawValue      : NSLocalizedString("Automatically approve everyone's comments.", comment: "")
        ]
    }
    
    
    
    
    // MARK: - Helpers
    
    /**
    *  @details Computed property, meant to help conversion from Remote / String-Based values, into their
    *           Integer counterparts
    */
    public var commentsSortOrderAscending : Bool {
        set {
            commentsSortOrder = newValue ? SortOrder.Ascending.rawValue : SortOrder.Descending.rawValue
        }
        get {
            return commentsSortOrder == SortOrder.Ascending.rawValue
        }
    }
    
    public var commentsAutoapproval : AutomaticallyApprove {
        get {
            if commentsRequireManualModeration {
                return .Disabled
            } else if commentsFromKnownUsersWhitelisted {
                return .FromKnownUsers
            }
            return .Everything
        }
        set {
            commentsRequireManualModeration     = newValue == .Disabled
            commentsFromKnownUsersWhitelisted   = newValue == .FromKnownUsers
        }
    }
}
