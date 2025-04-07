import Foundation

extension AbstractPost: SearchableItemConvertable {
    public var searchItemType: SearchItemType {
        return .abstractPost
    }

    public var isSearchable: Bool {
        guard status != .trash else {
            // Don't index trashed posts
            return false
        }
        return true
    }

    public var searchIdentifier: String? {
        guard let postID, postID.intValue > 0 else {
            return nil
        }
        return postID.stringValue
    }

    public var searchDomain: String? {
        if let dotComID = blog.dotComID, dotComID.intValue > 0 {
            return dotComID.stringValue
        } else {
            // This is a self-hosted site, set domain to the xmlrpc string
            return blog.xmlrpc
        }
    }

    public var searchTitle: String? {
        return generateTitle(from: postTitle)
    }

    public var searchDescription: String? {
        guard let postPreview = contentPreviewForDisplay(), !postPreview.isEmpty else {
            return blog.displayURL as String? ?? contentForDisplay()
        }
        return postPreview
    }

    public var searchKeywords: [String]? {
        return generateKeywordsFromContent()
    }

    public var searchExpirationDate: Date? {
        // Use the default expiration in spotlight.
        return nil
    }
}

// MARK: - Private Helper Functions

fileprivate extension AbstractPost {
    func generateKeywordsFromContent() -> [String]? {
        var keywords: [String]? = nil
        if let postTitle {
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
        if let postTitle, !postTitle.isEmpty {
            title = postTitle
        }

        guard status != .publish, let status else {
            return title
        }
        return "[\(AbstractPost.title(for: status))] \(title)"
    }
}
