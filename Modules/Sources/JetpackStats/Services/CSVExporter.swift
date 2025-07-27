import Foundation

protocol CSVExporterProtocol {
    func generateCSV(from items: [any TopListItemProtocol], metric: SiteMetric) -> String
}

struct CSVExporter: CSVExporterProtocol {
    func generateCSV(from items: [any TopListItemProtocol], metric: SiteMetric) -> String {
        guard !items.isEmpty else { return "" }
        
        // Get the type of the first item to access static headers
        let itemType = type(of: items.first!)
        guard let exportableType = itemType as? any CSVExportable.Type else {
            return ""
        }
        
        // Build CSV content
        var csvContent = [String]()
        
        // Get headers and append metric name
        var headers = exportableType.csvHeaders
        headers.append(metric.localizedTitle)
        csvContent.append(headers.map { escapeCSVField($0) }.joined(separator: ","))
        
        // Add rows
        for item in items {
            guard let exportableItem = item as? CSVExportable else { continue }
            
            // Get the values and append metric value
            var values = exportableItem.csvValues
            let metricValue = "\(item.metrics[metric] ?? 0)"
            values.append(metricValue)
            
            let escapedRow = values.map { escapeCSVField($0) }
            csvContent.append(escapedRow.joined(separator: ","))
        }
        
        return csvContent.joined(separator: "\n")
    }
    
    private func escapeCSVField(_ field: String) -> String {
        // Check if field needs escaping
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            // Escape quotes by doubling them and wrap in quotes
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}