import Foundation
import WordPressKit

final class AtomicSiteService {
    private let contextManager: CoreDataStackSwift
    private let remote: AtomicSiteServiceRemote

    required init(contextManager: CoreDataStackSwift = ContextManager.shared,
                  remote: AtomicSiteServiceRemote? = nil) {
        self.contextManager = contextManager
        self.remote = remote ?? AtomicSiteServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: contextManager.mainContext, localeKey: WordPressComRestApi.LocaleKeyV2))
    }

    func errorLogs(
        siteID: Int,
        range: Range<Date>,
        severity: AtomicErrorLogEntry.Severity? = nil,
        scrollID: String? = nil
    ) async throws -> AtomicErrorLogsResponse {
        try await withUnsafeThrowingContinuation { continuation in
            self.remote.getErrorLogs(siteID: siteID, range: range, severity: severity, scrollID: scrollID, success: continuation.resume, failure: continuation.resume)
        }
    }

    func webServerLogs(
        siteID: Int,
        range: Range<Date>,
        httpMethod: String? = nil,
        statusCode: Int? = nil,
        scrollID: String? = nil
    ) async throws -> AtomicWebServerLogsResponse {
        try await withUnsafeThrowingContinuation { continuation in
            self.remote.getWebServerLogs(siteID: siteID, range: range, httpMethod: httpMethod, statusCode: statusCode, scrollID: scrollID, pageSize: 5, success: continuation.resume, failure: continuation.resume)
        }
    }
}
