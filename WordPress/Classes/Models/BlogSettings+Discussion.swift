import Foundation


/**
 *  @extension  BlogSettings+Discussion
 *  @brief      In this extension, we implement several nested Enums (and helper setters / getters)
 *              aimed at simplifying the BlogSettings interface.
 *              This may be considered as an Adapter class, *Swift* style!
 */

extension BlogSettings
{
    /**
     *  @enum   BlogSettings.CommentsAutoapproval
     *  @brief  Enumerates all of the Comments AutoApproval settings
     */
    enum CommentsAutoapproval : Int {
        case Disabled       = 0
        case FromKnownUsers = 1
        case Everything     = 2
        
        
        /**
         *  @details Returns the localized description of the current enum value
         */
        var description : String {
            return CommentsAutoapproval.descriptionMap[rawValue]!
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the Localized Enum Titles.
         *           Order is guarranteed to match exactly with *allValues*.
         */
        static var allTitles : [String] {
            return allValues.flatMap { descriptionMap[$0] }
        }

        /**
         *  @details Returns the sorted collection of Localized Hints for all of the Enum Case's.
         *           Order is guarranteed to match exactly with *allValues*.
         */
        static var allHints : [String] {
            return allValues.flatMap { hintsMap[$0] }
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the possible Enum Values.
         */
        static var allValues : [Int] {
            return descriptionMap.keys.sort()
        }
        
        
        // MARK: - Private Properties
        
        private static let descriptionMap = [
            Disabled.rawValue       : NSLocalizedString("No comments", comment: ""),
            FromKnownUsers.rawValue : NSLocalizedString("Known user's comments", comment: ""),
            Everything.rawValue     : NSLocalizedString("All comments", comment: "")
        ]
        
        private static let hintsMap = [
            Disabled.rawValue       : NSLocalizedString("Require manual approval for everyone's comments.", comment: ""),
            FromKnownUsers.rawValue : NSLocalizedString("Automatically approve if the user has a previously approved comment.", comment: ""),
            Everything.rawValue     : NSLocalizedString("Automatically approve everyone's comments.", comment: "")
        ]
    }
    
    
    
    /**
     *  @enum   BlogSettings.CommentsSorting
     *  @brief  Enumerates all of the valid Comment Sort Order options
     */
    enum CommentsSorting : Int {
        case Ascending  = 0
        case Descending = 1
        
        
        /**
         *  @details Returns the localized description of the current enum value
         */
        var description : String {
            return CommentsSorting.descriptionMap[rawValue]!
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the Localized Enum Titles.
         *           Order is guarranteed to match exactly with *allValues*.
         */
        static var allTitles : [String] {
            return allValues.flatMap { descriptionMap[$0] }
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the possible Enum Values.
         */
        static var allValues : [Int] {
            return descriptionMap.keys.sort()
        }
        
        
        // MARK: - Private Properties
        
        private static var descriptionMap = [
            Ascending.rawValue  : NSLocalizedString("Oldest first", comment: "Sort Order"),
            Descending.rawValue : NSLocalizedString("Newest first", comment: "Sort Order")
        ]
    }

    
    
    /**
     *  @enum   BlogSettings.CommentsThreading
     *  @brief  Enumerates all of the valid Threading options
     */
    enum CommentsThreading {
        case Disabled
        case Enabled(depth: Int)
        
        
        /**
         *  @details Designated Initializer
         *  @param   rawValue       The Threading raw value (Core Data Integer)
         */
        init?(rawValue : Int) {
            switch rawValue {
            case _ where rawValue == CommentsThreading.disabledValue:
                self = .Disabled
            case _ where rawValue >= CommentsThreading.minimumValue && rawValue <= CommentsThreading.maximumValue:
                self = .Enabled(depth: rawValue)
            default:
                return nil
            }
        }
        
        
        /**
         *  @details Returns the Raw Value (for Core Data / Transport Layer usage)
         */
        var rawValue : Int {
            switch self {
            case .Disabled:
                return CommentsThreading.disabledValue
            case .Enabled(let depth):
                return depth
            }
        }
        
        
        /**
         *  @details Returns the localized description of the current enum value
         */
        var description : String {
            return CommentsThreading.descriptionMap[rawValue]!
        }
        
        
        /**
         *  @details Convenience helper that will return *true* whenever the case is *Disabled*
         */
        var isDisabled : Bool {
            return rawValue == CommentsThreading.disabledValue
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the Localized Enum Titles.
         *           Order is guarranteed to match exactly with *allValues*.
         */
        static var allTitles : [String] {
            return allValues.flatMap { descriptionMap[$0] }
        }
        
        
        /**
         *  @details Returns the sorted collection of all of the possible Enum Values.
         */
        static var allValues : [Int] {
            return descriptionMap.keys.sort()
        }
        
        
        // MARK: - Private Properties
        
        private static let disabledValue = 0
        private static let minimumValue  = 2
        private static let maximumValue  = 10
        
        private static var descriptionMap : [Int : String] {
            let descriptionFormat = NSLocalizedString("%@ levels", comment: "Comments Threading Levels")
            var optionsMap = [Int : String]()
            
            optionsMap[disabledValue] = NSLocalizedString("Disabled", comment: "")

            for currentLevel in minimumValue...maximumValue {
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
    var commentsAutoapproval : CommentsAutoapproval {
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
    var commentsSorting : CommentsSorting {
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
    var commentsSortOrderAscending : Bool {
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
    var commentsThreading : CommentsThreading {
        get {
            if commentsThreadingEnabled && commentsThreadingDepth != nil {
                return .Enabled(depth: commentsThreadingDepth as! Int)
            }
            
            return .Disabled
        }
        set {
            commentsThreadingEnabled = !newValue.isDisabled
            
            if !newValue.isDisabled {
                commentsThreadingDepth = newValue.rawValue
            }
        }
    }
}
