import Foundation

extension AbstractPost: SearchableItemConvertable {
    var searchItemType: SearchItemType {
        return .abstractPost
    }

    var isSearchable: Bool {
        guard status != .trash else {
            // Don't index trashed posts
            return false
        }
        guard blog.visible else {
            // Don't index posts for non-visible sites (not visible in the My Sites list)
            return false
        }
        return true
    }

    var searchIdentifier: String? {
        guard let postID = postID, postID.intValue > 0 else {
            return nil
        }
        return postID.stringValue
    }

    var searchDomain: String? {
        if let dotComID = blog.dotComID, dotComID.intValue > 0 {
            return dotComID.stringValue
        } else {
            // This is a self-hosted site, set domain to the xmlrpc string
            return blog.xmlrpc
        }
    }

    var searchTitle: String? {
        return generateTitle(from: postTitle)
    }

    var searchDescription: String? {
        guard let postPreview = contentPreviewForDisplay(), !postPreview.isEmpty else {
            return blog.displayURL as String? ?? contentForDisplay()
        }
        return postPreview
    }

    var searchKeywords: [String]? {
        return generateKeywordsFromContent()
    }

    var searchExpirationDate: Date? {
        // Use the default expiration in spotlight.
        return nil
    }
}

// MARK: - Private Helper Functions

fileprivate extension AbstractPost {
    func generateKeywordsFromContent() -> [String]? {
        var keywords: [String]? = nil
        if let postTitle = postTitle {
            // Try to generate some keywords from the title...
            keywords = postTitle.components(separatedBy: " ").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        } else if !contentPreviewForDisplay().isEmpty {
            // ...otherwise try to generate some keywords from the content preview
            keywords = contentPreviewForDisplay().components(separatedBy: " ").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        }
        return keywords
    }

    func generateTitle(from postTitle: String?) -> String {
        let noTitleText = NSLocalizedString("No Title", comment: "Label used for posts without a title in spotlight search.")
        var title = "(\(noTitleText))"
        if let postTitle = postTitle, !postTitle.isEmpty {
            title = postTitle
        }

        guard status != .publish, let statusTitle = statusTitle else {
            return title
        }
        return "[\(statusTitle)] \(title)"
    }
}
