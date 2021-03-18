import Foundation


/// In this extension, we implement several nested Enums (and helper setters / getters)  aimed at simplifying
/// the BlogSettings interface. This may be considered as an Adapter class, *Swift* style!
///
extension BlogSettings {
    /// Enumerates all of the Comments AutoApproval settings
    ///
    enum CommentsAutoapproval: Int {
        case disabled       = 0
        case fromKnownUsers = 1
        case everything     = 2


        /// Returns the localized description of the current enum value
        ///
        var description: String {
            return CommentsAutoapproval.descriptionMap[rawValue]!
        }


        /// Returns the sorted collection of all of the Localized Enum Titles.
        /// Order is guarranteed to match exactly with *allValues*.
        ///
        static var allTitles: [String] {
            return allValues.compactMap { descriptionMap[$0] }
        }

        /// Returns the sorted collection of Localized Hints for all of the Enum Case's.
        /// Order is guarranteed to match exactly with *allValues*.
        ///
        static var allHints: [String] {
            return allValues.compactMap { hintsMap[$0] }
        }


        /// Returns the sorted collection of all of the possible Enum Values.
        ///
        static var allValues: [Int] {
            return descriptionMap.keys.sorted()
        }


        // MARK: - Private Properties

        fileprivate static let descriptionMap = [
            disabled.rawValue: NSLocalizedString("No comments", comment: "An option in a list. Automatically approve no comments."),
            fromKnownUsers.rawValue: NSLocalizedString("Known user's comments", comment: "An option in a list. Automatically approve comments from known users."),
            everything.rawValue: NSLocalizedString("All comments", comment: "An option in a list. Automatically approve all comments")
        ]

        fileprivate static let hintsMap = [
            disabled.rawValue: NSLocalizedString("Require manual approval for everyone's comments.", comment: "Explains the effect of the 'No comments' auto approval setting."),
            fromKnownUsers.rawValue: NSLocalizedString("Automatically approve if the user has a previously approved comment.", comment: "Explains the effect of the 'Known users' auto approval setting"),
            everything.rawValue: NSLocalizedString("Automatically approve everyone's comments.", comment: "Explains the effect of the 'All comments' auto approval setting")
        ]
    }



    /// Enumerates all of the valid Comment Sort Order options
    ///
    enum CommentsSorting: Int {
        case ascending  = 0
        case descending = 1


        /// Returns the localized description of the current enum value
        ///
        var description: String {
            return CommentsSorting.descriptionMap[rawValue]!
        }


        /// Returns the sorted collection of all of the Localized Enum Titles.
        /// Order is guarranteed to match exactly with *allValues*.
        ///
        static var allTitles: [String] {
            return allValues.compactMap { descriptionMap[$0] }
        }


        /// Returns the sorted collection of all of the possible Enum Values.
        ///
        static var allValues: [Int] {
            return descriptionMap.keys.sorted()
        }


        // MARK: - Private Properties

        fileprivate static var descriptionMap = [
            ascending.rawValue: NSLocalizedString("Oldest first", comment: "Sort Order"),
            descending.rawValue: NSLocalizedString("Newest first", comment: "Sort Order")
        ]
    }



    /// Enumerates all of the valid Threading options
    ///
    enum CommentsThreading {
        case disabled
        case enabled(depth: Int)


        /// Designated Initializer
        ///
        /// - Parameter rawValue: The Threading raw value (Core Data Integer)
        ///
        init?(rawValue: Int) {
            switch rawValue {
            case _ where rawValue == CommentsThreading.disabledValue:
                self = .disabled
            case _ where rawValue >= CommentsThreading.minimumValue && rawValue <= CommentsThreading.maximumValue:
                self = .enabled(depth: rawValue)
            default:
                return nil
            }
        }


        /// Returns the Raw Value (for Core Data / Transport Layer usage)
        ///
        var rawValue: Int {
            switch self {
            case .disabled:
                return CommentsThreading.disabledValue
            case .enabled(let depth):
                return depth
            }
        }


        /// Returns the localized description of the current enum value
        ///
        var description: String {
            return CommentsThreading.descriptionMap[rawValue]!
        }


        /// Convenience helper that will return *true* whenever the case is *Disabled*
        ///
        var isDisabled: Bool {
            return rawValue == CommentsThreading.disabledValue
        }


        /// Returns the sorted collection of all of the Localized Enum Titles.
        /// Order is guarranteed to match exactly with *allValues*.
        ///
        static var allTitles: [String] {
            return allValues.compactMap { descriptionMap[$0] }
        }


        /// Returns the sorted collection of all of the possible Enum Values.
        ///
        static var allValues: [Int] {
            return descriptionMap.keys.sorted()
        }


        // MARK: - Private Properties

        fileprivate static let disabledValue = 0
        fileprivate static let minimumValue  = 2
        fileprivate static let maximumValue  = 10

        fileprivate static var descriptionMap: [Int: String] {
            let descriptionFormat = NSLocalizedString("%@ levels", comment: "Comments Threading Levels")
            var optionsMap = [Int: String]()

            optionsMap[disabledValue] = NSLocalizedString("Disabled", comment: "Adjective. Comment threading is disabled.")

            for currentLevel in minimumValue...maximumValue {
                let level = NumberFormatter.localizedString(from: NSNumber(value: currentLevel), number: .spellOut)
                optionsMap[currentLevel] = String(format: descriptionFormat, level.capitalized)
            }

            return optionsMap
        }
    }



    // MARK: - Swift Adapters


    /// Wraps Core Data values into Swift's CommentsAutoapproval Enum
    ///
    var commentsAutoapproval: CommentsAutoapproval {
        get {
            if commentsRequireManualModeration {
                return .disabled
            } else if commentsFromKnownUsersAllowlisted {
                return .fromKnownUsers
            }

            return .everything
        }
        set {
            commentsRequireManualModeration     = newValue == .disabled
            commentsFromKnownUsersAllowlisted   = newValue == .fromKnownUsers
        }
    }


    /// Wraps Core Data values into Swift's CommentsSorting Enum
    ///
    var commentsSorting: CommentsSorting {
        get {
            guard let sortOrder = commentsSortOrder as? Int,
                let sorting = CommentsSorting(rawValue: sortOrder) else {
                    return .ascending
            }
            return sorting
        }
        set {
            commentsSortOrder = newValue.rawValue as NSNumber?
        }
    }


    /// Helper, to aid in setting SortOrder in ObjC code. True when Ascending, False otherwise.
    ///
    @objc var commentsSortOrderAscending: Bool {
        get {
            return commentsSortOrder?.intValue == CommentsSorting.ascending.rawValue
        }
        set {
            commentsSortOrder = newValue ? CommentsSorting.ascending.rawValue as NSNumber? : CommentsSorting.descending.rawValue as NSNumber?
        }
    }


    /// Wraps Core Data values into Swift's CommentsThreading Enum
    ///
    var commentsThreading: CommentsThreading {
        get {
            if commentsThreadingEnabled && commentsThreadingDepth != nil {
                return .enabled(depth: commentsThreadingDepth as! Int)
            }

            return .disabled
        }
        set {
            commentsThreadingEnabled = !newValue.isDisabled

            if !newValue.isDisabled {
                commentsThreadingDepth = newValue.rawValue as NSNumber?
            }
        }
    }
}
