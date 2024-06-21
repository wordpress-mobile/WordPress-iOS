import XCTest
@testable import WordPressKit

final class IPLocationRemoteTests: XCTestCase {
    var remote: IPLocationRemote!
    let apiURL = URL(string: "https://public-api.wordpress.com/geo/")!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)

        remote = IPLocationRemote(urlSession: urlSession)
    }

    func testCountryCodeIsCorrectlyParsed() {
        let expectation = expectation(description: "The country code should be parsed as DE")
        let jsonString = """
                         {
                             "latitude": "24.917202",
                             "longitude": "16.559613",
                             "country_short": "DE",
                             "country_long": "Germany",
                             "region": "Brandenburg",
                             "city": "Potsdam"
                         }
                         """

        let data = jsonString.data(using: .utf8)

        MockURLProtocol.requestHandler = { request in
          let response = HTTPURLResponse(url: self.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
          return (response, data)
        }

        remote.fetchIPCountryCode { result in
          switch result {
          case .success(let countryCode):
            XCTAssertEqual(countryCode, "DE")
          case .failure(let error):
            XCTFail("Error was not expected: \(error)")
          }
          expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}
