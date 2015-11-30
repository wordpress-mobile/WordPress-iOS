import Foundation



/**
 *  @extension      BlogSettings
 *  @brief
 */

extension BlogSettings
{
    /**
     *  @enum    BlogSettings.CommentsAutoapproval
     *  @brief   Enumerates all of the Comments AutoApproval settings
     */
    public enum CommentsAutoapproval : Int {
        case Disabled       = 0
        case FromKnownUsers = 1
        case Everything     = 2
        
        
        /**
         *  @details Returns the localized description of the current enum value
         */
        public var description : String {
            return CommentsAutoapproval.DescriptionMap[rawValue]!
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the Localized Enum Titles.
         *           Order is guarranteed to match exactly with *AllValues*.
         */
        public static var AllTitles : [String] {
            return AllValues.flatMap { DescriptionMap[$0] }
        }

        /**
         *  @details Returns the sorted collection of Localized Hints for all of the Enum Case's.
         *           Order is guarranteed to match exactly with *AllValues*.
         */
        public static var AllHints : [String] {
            return AllValues.flatMap { HintsMap[$0] }
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the possible Enum Values.
         */
        public static var AllValues : [Int] {
            return DescriptionMap.keys.sort()
        }
        
        
        // MARK: - Private Properties
        
        private static let DescriptionMap = [
            Disabled.rawValue       : NSLocalizedString("No comments", comment: ""),
            FromKnownUsers.rawValue : NSLocalizedString("Known user's comments", comment: ""),
            Everything.rawValue     : NSLocalizedString("All comments", comment: "")
        ]
        
        private static let HintsMap = [
            Disabled.rawValue       : NSLocalizedString("Require manual approval for everyone's comments.", comment: ""),
            FromKnownUsers.rawValue : NSLocalizedString("Automatically approve if the user has a previously approved comment.", comment: ""),
            Everything.rawValue     : NSLocalizedString("Automatically approve everyone's comments.", comment: "")
        ]
    }
    
    
    
    /**
     *  @enum    BlogSettings.CommentsSorting
     *  @brief   Enumerates all of the valid Comment Sort Order options
     */
    public enum CommentsSorting : Int {
        case Ascending  = 0
        case Descending = 1
        
        
        /**
         *  @details Returns the localized description of the current enum value
         */
        public var description : String {
            return CommentsSorting.DescriptionMap[rawValue]!
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the Localized Enum Titles.
         *           Order is guarranteed to match exactly with *AllValues*.
         */
        public static var AllTitles : [String] {
            return AllValues.flatMap { DescriptionMap[$0] }
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the possible Enum Values.
         */
        public static var AllValues : [Int] {
            return DescriptionMap.keys.sort()
        }
        
        
        // MARK: - Private Properties
        
        private static var DescriptionMap = [
            Ascending.rawValue  : NSLocalizedString("Oldest first", comment: "Sort Order"),
            Descending.rawValue : NSLocalizedString("Newest first", comment: "Sort Order")
        ]
    }

    
    
    /**
     *  @enum    BlogSettings.CommentsThreading
     *  @brief   Enumerates all of the valid Threading options
     */
    public enum CommentsThreading {
        case Disabled
        case Enabled(depth: Int)
        
        
        /**
         *  @details Designated Initializer
         *  @param   rawValue       The Threading raw value (Core Data Integer)
         */
        init?(rawValue : Int) {
            switch rawValue {
            case _ where rawValue == CommentsThreading.DisabledValue:
                self = .Disabled
            case _ where rawValue >= CommentsThreading.MinimumValue && rawValue <= CommentsThreading.MaximumValue:
                self = .Enabled(depth: rawValue)
            default:
                return nil
            }
        }
        
        
        /**
         *  @details Returns the Raw Value (for Core Data / Transport Layer usage)
         */
        public var rawValue : Int {
            switch self {
            case .Disabled:
                return CommentsThreading.DisabledValue
            case .Enabled(let depth):
                return depth
            }
        }
        
        
        /**
         *  @details Returns the localized description of the current enum value
         */
        public var description : String {
            return CommentsThreading.DescriptionMap[rawValue]!
        }
        
        
        /**
         *  @details Convenience helper that will return *true* whenever the case is *Disabled*
         */
        public var isDisabled : Bool {
            return rawValue == CommentsThreading.DisabledValue
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the Localized Enum Titles.
         *           Order is guarranteed to match exactly with *AllValues*.
         */
        public static var AllTitles : [String] {
            return AllValues.flatMap { DescriptionMap[$0] }
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the possible Enum Values.
         */
        public static var AllValues : [Int] {
            return DescriptionMap.keys.sort()
        }
        
        
        // MARK: - Private Properties
        
        private static let DisabledValue = 0
        private static let MinimumValue  = 2
        private static let MaximumValue  = 10
        
        private static var DescriptionMap : [Int : String] {
            let descriptionFormat = NSLocalizedString("%@ levels", comment: "Comments Threading Levels")
            var optionsMap = [Int : String]()
            
            optionsMap[DisabledValue] = NSLocalizedString("Disabled", comment: "")

            for currentLevel in MinimumValue...MaximumValue {
                let level = NSNumberFormatter.localizedStringFromNumber(currentLevel, numberStyle: .SpellOutStyle)
                optionsMap[currentLevel] = String(format: descriptionFormat, level.capitalizedString)
            }
            
            return optionsMap
        }
    }
    
    
    
    // MARK: - Swift Adapters
    
    
    /**
    *  @details Wraps Core Data values into Swift's CommentsAutoapproval Enum
    */
    public var commentsAutoapproval : CommentsAutoapproval {
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
    
    
    /**
     *  @details Wraps Core Data values into Swift's CommentsSorting Enum
     */
    public var commentsSorting : CommentsSorting {
        get {
            return CommentsSorting(rawValue: commentsSortOrder as! Int) ?? .Ascending
        }
        set {
            commentsSortOrder = newValue.rawValue
        }
    }
    
    
    /**
     *  @details Helper, to aid in setting SortOrder in ObjC code. True when Ascending, False otherwise.
     */
    public var commentsSortOrderAscending : Bool {
        get {
            return commentsSortOrder == CommentsSorting.Ascending.rawValue
        }
        set {
            commentsSortOrder = newValue ? CommentsSorting.Ascending.rawValue : CommentsSorting.Descending.rawValue
        }
    }
    
    
    /**
    *  @details Wraps Core Data values into Swift's CommentsThreading Enum
     */
    public var commentsThreading : CommentsThreading {
        get {
            if commentsThreadingEnabled && commentsThreadingDepth != nil {
                return .Enabled(depth: commentsThreadingDepth as! Int)
            }
            
            return .Disabled
        }
        set {
            commentsThreadingEnabled = !newValue.isDisabled
            commentsThreadingDepth = newValue.rawValue
        }
    }
}
