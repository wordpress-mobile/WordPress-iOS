import Foundation

extension ReaderPost: SearchableItemConvertable {
    var searchItemType: SearchItemType {
        return .readerPost
    }

    var isSearchable: Bool {
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
        var title = titleForDisplay() ?? ""
        if title.isEmpty {
            // If titleForDisplay() happens to be empty, try using the content preview instead...
            title = contentPreviewForDisplay()
        }
        return title
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
        let oneWeekFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        return oneWeekFromNow
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
