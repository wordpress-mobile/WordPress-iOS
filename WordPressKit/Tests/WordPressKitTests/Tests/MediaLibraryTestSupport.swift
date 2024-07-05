import Foundation
import XCTest
import UniformTypeIdentifiers
import OHHTTPStubs
import OHHTTPStubsSwift
import wpxmlrpc

/// This type acts like a WordPress Media Library. It can be used in test cases to stub loading media library content
/// API calls and provides a close-to-production API responses, which relieves test cases from the burden of creating
/// appropriate responses.
///
/// This class creates many dummy media items upon initlisation. Test cases can call the `stubREST` or `stubRPC`
/// function to create an HTTP stub for WordPress.com REST API or WordPress XML-RPC API that are used in the
/// `-[MediaServiceRemote getMediaLibraryWithPageLoad:success:failure:]` method. The stubs parse the pagination
/// parameters in the API requests and returns appropriate media items accordingly.
class MediaLibraryTestSupport {
    private let media: [Media]

    private var restStub: HTTPStubsDescriptor? {
        didSet {
            if let oldValue {
                HTTPStubs.removeStub(oldValue)
            }
        }
    }

    private var rpcStub: HTTPStubsDescriptor? {
        didSet {
            if let oldValue {
                HTTPStubs.removeStub(oldValue)
            }
        }
    }

    init(totalMedia: Int) {
        media = (1...totalMedia).map { id in
            Media(
                mediaID: id,
                postID: (1...12345).randomElement()!,
                mimeType: ["image/png", "audio/mp3", "video/mp4"].randomElement()!,
                cusor: UUID().uuidString
            )
        }
    }

    deinit {
        restStub = nil
        rpcStub = nil
    }
}

extension MediaLibraryTestSupport {

    func stubREST(siteID: Int, failAtPage pageToFail: Int) {
        restStub = stub(condition: isPath("/rest/v1.1/sites/\(siteID)/media")) { [weak self] request in
            self?.handleREST(request: request, failAtPage: pageToFail) ?? .init(error: URLError(.networkConnectionLost))
        }
    }

    private func handleREST(request: URLRequest, failAtPage pageToFail: Int) -> HTTPStubsResponse {
        let cursor = request.url?.query("page_handle") ?? nil
        let number = request.url?.query("number").flatMap(Int.init(_:)) ?? 100

        let cursorIndex = media.firstIndex { $0.cusor == cursor } ?? 0
        let requestPage = (cursorIndex / number) + 1

        if pageToFail == requestPage {
            return .init(error: URLError(.cannotFindHost))
        }

        let range = cursorIndex...min(cursorIndex + number - 1, media.count - 1)
        let json: [String: Any] = [
            "media": media[range].map { $0.asRESTResponse() },
            "meta": [
                "next_page": range.upperBound + 1 < media.count ? media[range.upperBound + 1].cusor : ""
            ]
        ]

        return .init(jsonObject: json, statusCode: 200, headers: nil)
    }

}

extension MediaLibraryTestSupport {

    func stubRPC(endpoint: URL, failAtPage pageToFail: Int) {
        rpcStub = stub(condition: isMethodPOST() && isAbsoluteURLString(endpoint.absoluteString)) { [weak self] request in
            self?.handleRPC(request: request, failAtPage: pageToFail) ?? .init(error: URLError(.networkConnectionLost))
        }
    }

    private func handleRPC(request: URLRequest, failAtPage pageToFail: Int) -> HTTPStubsResponse {
        let parser: XMLParser
        if let stream = request.httpBodyStream {
            parser = XMLParser(stream: stream)
        } else if let body = request.httpBody {
            parser = XMLParser(data: body)
        } else {
            XCTFail("The request doesn't have a request body: \(request)")
            return .init(error: URLError(.cannotDecodeContentData))
        }

        let delegate = RequestParser()
        parser.delegate = delegate
        guard parser.parse() else {
            XCTFail("Unexpected error: \(String(describing: parser.parserError))")
            return .init(error: URLError(.cannotDecodeContentData))
        }

        XCTAssertEqual(delegate.methodName, "wp.getMediaLibrary")

        let number = delegate.params["number"] as? Int ?? 100
        let offset = delegate.params["offset"] as? Int ?? 0
        let requestPage = (offset / number) + 1

        if pageToFail == requestPage {
            return .init(error: URLError(.cannotFindHost))
        }

        let range = offset...min(offset + number - 1, media.count - 1)

        do {
            let data = try WPXMLRPCEncoder(responseParams: [media[range].map { $0.asRPCResponse() }]).dataEncoded()
            return .init(data: data, statusCode: 200, headers: ["Content-Type": "application/xml"])
        } catch {
            return .init(error: error)
        }
    }

    private class RequestParser: NSObject, XMLParserDelegate {
        var elementPath: [String] = []
        var methodName: String?
        var params: [String: Any] = [:]
        var content: String?
        var paramName: String?

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            elementPath.append(elementName)
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            self.content = string
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            assert(elementName == elementPath.last)

            defer {
                self.content = nil
                elementPath.removeLast()
            }

            switch elementPath {
            case ["methodCall", "methodName"]:
                self.methodName = self.content
            case ["methodCall", "params", "param", "value", "struct", "member", "name"]:
                self.paramName = self.content
            case ["methodCall", "params", "param", "value", "struct", "member", "value", "i4"]:
                self.params[self.paramName!] = Int(self.content!)
                self.paramName = nil
            default:
                break
            }
        }
    }

}

private struct Media: Codable {
    var mediaID: Int
    var postID: Int
    var mimeType: String

    var cusor: String

    func asRESTResponse() -> [String: Any] {
        [
            "ID": mediaID,
            "post_ID": postID,
            "mime_type": mimeType
        ]
    }

    func asRPCResponse() -> [String: Any] {
        [
            "id": mediaID,
            "parent": postID,
            "type": mimeType
        ]
    }
}

private extension URL {
    func query(_ name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}
