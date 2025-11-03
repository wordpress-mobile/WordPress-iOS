import Foundation
import CoreData
import WordPressShared
import WordPressAPI

extension Blog {

    /// The title of the blog
    public var title: String? {
        guard let blogName = settings?.name, !blogName.isEmpty else {
            return displayURL as String?
        }
        return blogName
    }

    // MARK: - Post Formats

    /// Returns an array of post format keys sorted with "standard" first, then alphabetically
    @objc public var sortedPostFormats: [String] {
        guard let postFormats = postFormats as? [String: String], !postFormats.isEmpty else {
            return []
        }

        var sortedFormats: [String] = []

        // Add standard format first if it exists
        if postFormats[PostFormatStandard] != nil {
            sortedFormats.append(PostFormatStandard)
        }

        // Add remaining formats sorted by their display names
        let nonStandardFormats = postFormats
            .filter { $0.key != PostFormatStandard }
            .sorted { $0.value.localizedCaseInsensitiveCompare($1.value) == .orderedAscending }
            .map { $0.key }

        sortedFormats.append(contentsOf: nonStandardFormats)

        return sortedFormats
    }

    /// Returns an array of post format display names sorted with "Standard" first, then alphabetically
    @objc public var sortedPostFormatNames: [String] {
        guard let postFormats = postFormats as? [String: String] else {
            return []
        }
        return sortedPostFormats.compactMap { postFormats[$0] }
    }

    /// Returns the default post format display text
    @objc public var defaultPostFormatText: String? {
        postFormatText(fromSlug: settings?.defaultPostFormat)
    }

    // MARK: - Connections

    /// Returns an array of PublicizeConnection objects sorted by service name, then by external name
    @objc public var sortedConnections: [PublicizeConnection] {
        guard let connections = Array(connections ?? []) as? [PublicizeConnection] else {
            return []
        }
        return connections.sorted { lhs, rhs in
            // First sort by service name (case insensitive, localized)
            let serviceComparison = lhs.service.localizedCaseInsensitiveCompare(rhs.service)
            if serviceComparison != .orderedSame {
                return serviceComparison == .orderedAscending
            }
            // Then sort by external name (case insensitive)
            return lhs.externalName.caseInsensitiveCompare(rhs.externalName) == .orderedAscending
        }
    }

    // MARK: - Roles

    /// Returns an array of roles sorted by order.
    public var sortedRoles: [Role] {
        guard let roles = Array(roles ?? []) as? [Role] else {
            return []
        }
        return roles.sorted { lhs, rhs in
            (lhs.order?.intValue ?? 0) < (rhs.order?.intValue ?? 0)
        }
    }

    public var taxonomies: [SiteTaxonomy] {
        get throws {
            try rawTaxonomies.flatMap { try JSONDecoder().decode([SiteTaxonomy].self, from: $0) } ?? []
        }
    }

    public func setTaxonomies(_ taxonomies: [SiteTaxonomy]) throws {
        self.rawTaxonomies = try JSONEncoder().encode(taxonomies)
    }
}
