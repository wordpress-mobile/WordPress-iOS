import Foundation

protocol CSVExportable {
    static var csvHeaders: [String] { get }
    var csvValues: [String] { get }
}

extension TopListItem.Post: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.title,
            Strings.CSVExport.url,
            Strings.CSVExport.date,
            Strings.CSVExport.type,
        ]
    }

    var csvValues: [String] {
        [
            title,
            postURL?.absoluteString ?? "",
            date?.formatted(date: .abbreviated, time: .omitted) ?? "",
            type ?? ""
        ]
    }
}

extension TopListItem.Referrer: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.name,
            Strings.CSVExport.domain
        ]
    }

    var csvValues: [String] {
        [
            name,
            domain ?? ""
        ]
    }
}

extension TopListItem.Location: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.country,
            Strings.CSVExport.countryCode
        ]
    }

    var csvValues: [String] {
        [
            name,
            countryCode ?? ""
        ]
    }
}

extension TopListItem.Author: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.name,
            Strings.CSVExport.role
        ]
    }

    var csvValues: [String] {
        [
            name,
            role ?? ""
        ]
    }
}

extension TopListItem.ExternalLink: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.title,
            Strings.CSVExport.url
        ]
    }

    var csvValues: [String] {
        [
            title ?? url,
            url
        ]
    }
}

extension TopListItem.FileDownload: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.fileName,
            Strings.CSVExport.filePath
        ]
    }

    var csvValues: [String] {
        [
            fileName,
            filePath ?? ""
        ]
    }
}

extension TopListItem.SearchTerm: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.searchTerm
        ]
    }

    var csvValues: [String] {
        [
            term
        ]
    }
}

extension TopListItem.Video: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.title,
            Strings.CSVExport.videoURL
        ]
    }

    var csvValues: [String] {
        [
            title,
            videoURL?.absoluteString ?? ""
        ]
    }
}

extension TopListItem.ArchiveItem: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.name,
            Strings.CSVExport.url
        ]
    }

    var csvValues: [String] {
        [
            value,
            href
        ]
    }
}

extension TopListItem.ArchiveSection: CSVExportable {
    static var csvHeaders: [String] {
        [
            Strings.CSVExport.section
        ]
    }

    var csvValues: [String] {
        [
            displayName
        ]
    }
}
