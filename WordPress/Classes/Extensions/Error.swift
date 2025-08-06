import Foundation
import WordPressKit
import WordPressAPI

extension Error {
    func isCancellationError() -> Bool {
        let wrapped = self
        if wrapped is CancellationError {
            return true
        }

        if let error = wrapped as? URLError, error.code == .cancelled {
            return true
        }

        if let error = wrapped as? WordPressAPIError<WordPressOrgRestApiError>, error.urlError?.code == .cancelled {
            return true
        }

        if let error = wrapped as? WordPressAPIError<WordPressComRestApiEndpointError>, error.urlError?.code == .cancelled {
            return true
        }

        if let error = wrapped as? WpApiError, error.isCancellationError {
            return true
        }

        return false
    }
}

private extension WordPressAPIError {
    var urlError: URLError? {
        if case let .connection(error) = self {
            return error
        }
        return nil
    }
}
