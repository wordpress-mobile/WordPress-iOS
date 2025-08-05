import Foundation
import SwiftUI

protocol CSVExporterProtocol {
    func generateCSV(from items: [any TopListItemProtocol], metric: SiteMetric) -> String
}

/// Exports stats data to CSV format following RFC 4180 standard
struct CSVExporter: CSVExporterProtocol {
    // RFC 4180: Use CRLF for line endings
    static let lineEnding = "\r\n"

    // Characters that require field escaping according to RFC 4180
    static let charactersRequiringEscape = CharacterSet(charactersIn: ",\"\r\n")

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
        csvLines.append(Self.buildCSVRow(from: headers))

        // Build data rows
        for item in items {
            guard let exportableItem = item as? CSVExportable else { continue }

            let values = exportableItem.csvValues + [formatMetricValue(item.metrics[metric])]
            csvLines.append(Self.buildCSVRow(from: values))
        }

        return csvLines.joined(separator: Self.lineEnding)
    }

    /// Builds a CSV row from an array of values, properly escaping fields as needed
    static func buildCSVRow(from values: [String]) -> String {
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
    static func escapeCSVField(_ field: String) -> String {
        // Quick check if escaping is needed
        guard field.rangeOfCharacter(from: charactersRequiringEscape) != nil else {
            return field
        }

        // Escape quotes by doubling them and wrap the field in quotes
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

struct CSVDataRepresentation: Transferable {
    let items: [any TopListItemProtocol]
    let metric: SiteMetric
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        let dataRepresentation = DataRepresentation(exportedContentType: .commaSeparatedText) { (representation: CSVDataRepresentation) in
            try representation.generateCSVData()
        }
        if #available(iOS 17.0, *) {
            return dataRepresentation.suggestedFileName { $0.fileName }
        } else {
            return dataRepresentation
        }
    }

    private func generateCSVData() throws -> Data {
        let exporter = CSVExporter()
        let csvContent = exporter.generateCSV(from: items, metric: metric)
        guard let data = csvContent.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data
    }
}

struct ChartDataCSVRepresentation: Transferable {
    let data: ChartData
    let dateRange: StatsDateRange
    let context: StatsContext

    static var transferRepresentation: some TransferRepresentation {
        let dataRepresentation = DataRepresentation(exportedContentType: .commaSeparatedText) { (representation: ChartDataCSVRepresentation) in
            try representation.generateCSVData()
        }
        if #available(iOS 17.0, *) {
            return dataRepresentation.suggestedFileName { representation in
                let dateString = representation.context.formatters.dateRange.string(from: representation.dateRange.dateInterval)
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: ",", with: "")
                return "\(representation.data.metric.localizedTitle)-\(dateString).csv"
            }
        } else {
            return dataRepresentation
        }
    }

    private func generateCSVData() throws -> Data {
        let csvContent = generateCSV()
        guard let data = csvContent.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data
    }

    private func generateCSV() -> String {
        let formatter = StatsValueFormatter(metric: data.metric)
        var csvLines = [String]()

        // Header row
        let headers = [Strings.CSVExport.date, data.metric.localizedTitle]
        csvLines.append(CSVExporter.buildCSVRow(from: headers))

        // Data rows
        for point in data.currentData {
            let dateString = context.formatters.date.formatDate(point.date, granularity: data.granularity)
            let valueString = formatter.format(value: point.value)
            csvLines.append(CSVExporter.buildCSVRow(from: [dateString, valueString]))
        }

        return csvLines.joined(separator: CSVExporter.lineEnding)
    }
}
