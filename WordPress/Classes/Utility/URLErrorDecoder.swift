import Foundation

class URLErrorDecoder: NSObject {

    let error: NSError
    init(error: NSError) {
        self.error = error
    }

    func hasInternetConnectionRelatedError() -> Bool {

        let code = error.code
        return code == NSURLErrorCannotFindHost ||
               code == NSURLErrorCannotConnectToHost ||
               code == NSURLErrorNetworkConnectionLost ||
               code == NSURLErrorNotConnectedToInternet
    }
}
