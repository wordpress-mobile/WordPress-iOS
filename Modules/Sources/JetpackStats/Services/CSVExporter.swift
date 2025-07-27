import Foundation

protocol CSVExporterProtocol {
    func generateCSV(from items: [any TopListItemProtocol], metric: SiteMetric) -> String
}

/// Exports stats data to CSV format following RFC 4180 standard
struct CSVExporter: CSVExporterProtocol {
    // RFC 4180: Use CRLF for line endings
    private static let lineEnding = "\r\n"

    // Characters that require field escaping according to RFC 4180
    private static let charactersRequiringEscape = CharacterSet(charactersIn: ",\"\r\n")

    func generateCSV(from items: [any TopListItemProtocol], metric: SiteMetric) -> String {
        guard !items.isEmpty else { return "" }

        // Get the type of the first item to access static headers
        let itemType = type(of: items.first!)
        guard let exportableType = itemType as? any CSVExportable.Type else {
            return ""
        }

        // Pre-allocate capacity for better performance
        var csvLines = [String]()
        csvLines.reserveCapacity(items.count + 1)

        // Build header row
        let headers = exportableType.csvHeaders + [metric.localizedTitle]
        csvLines.append(buildCSVRow(from: headers))

        // Build data rows
        for item in items {
            guard let exportableItem = item as? CSVExportable else { continue }

            let values = exportableItem.csvValues + [formatMetricValue(item.metrics[metric])]
            csvLines.append(buildCSVRow(from: values))
        }

        return csvLines.joined(separator: Self.lineEnding)
    }

    /// Builds a CSV row from an array of values, properly escaping fields as needed
    private func buildCSVRow(from values: [String]) -> String {
        values
            .map { escapeCSVField($0) }
            .joined(separator: ",")
    }

    /// Formats a metric value for CSV export
    private func formatMetricValue(_ value: Int?) -> String {
        "\(value ?? 0)"
    }

    /// Escapes a CSV field according to RFC 4180 rules:
    /// - Fields containing comma, quotes, CR, or LF must be enclosed in double quotes
    /// - Double quotes within fields must be escaped by doubling them
    private func escapeCSVField(_ field: String) -> String {
        // Quick check if escaping is needed
        guard field.rangeOfCharacter(from: Self.charactersRequiringEscape) != nil else {
            return field
        }

        // Escape quotes by doubling them and wrap the field in quotes
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
