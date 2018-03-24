import Foundation

extension ReaderPost: SearchableItemConvertable {
    var searchItemType: SearchItemType {
        return .readerPost
    }

    var isSearchable: Bool {
        guard let title = searchTitle, !title.isEmpty else {
            // If the title is empty or nil, don't index it
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
        guard let siteID = siteID, siteID.intValue > 0 else {
            return nil
        }
        return siteID.stringValue
    }

    var searchTitle: String? {
        return titleForDisplay()
    }

    var searchDescription: String? {
        guard let readerPostPreview = contentPreviewForDisplay(), !readerPostPreview.isEmpty else {
            return siteURLForDisplay() ?? contentForDisplay()
        }
        return readerPostPreview
    }

    var searchKeywords: [String]? {
        return generateKeywordsFromContent()
    }

    var searchExpirationDate: Date? {
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        return sevenDaysFromNow
    }
}

// MARK: - Private Helper Functions

fileprivate extension ReaderPost {
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
}
