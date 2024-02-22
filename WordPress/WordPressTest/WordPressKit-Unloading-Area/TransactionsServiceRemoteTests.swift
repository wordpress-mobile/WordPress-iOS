import WordPressShared
@testable import WordPress
import XCTest

class TransactionsServiceRemoteTests: RemoteTestCase, RESTTestable {

    let supportedCountriesSuccessFileName = "supported-countries-success.json"
    var remote: TransactionsServiceRemote!

    override func setUp() {
        super.setUp()
        remote = TransactionsServiceRemote(wordPressComRestApi: getRestApi())
    }

    func testGetSupportedCountries() {
        let expect = expectation(description: "Get supported countries success")

        stubRemoteResponse("me/transactions/supported-countries/",
                           filename: supportedCountriesSuccessFileName,
                           contentType: .ApplicationJSON,
                           status: 200)

        remote.getSupportedCountries(success: { (countryList) in
            expect.fulfill()
            XCTAssert(countryList.count == 239)
            XCTAssert(countryList[0].code == "TR")
            XCTAssert(countryList[0].name == "Turkey")
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
