import Foundation
@testable import WordPress

class RegisterDomainDetailsServiceProxyMock: RegisterDomainDetailsServiceProxyProtocol {

    var success: Bool
    var emptyPrefillData: Bool

    init(success: Bool, emptyPrefillData: Bool = false) {
        self.success = success
        self.emptyPrefillData = emptyPrefillData
    }

    func validateDomainContactInformation(contactInformation: [String: String],
                                          domainNames: [String],
                                          success: @escaping (ValidateDomainContactInformationResponse) -> Void,
                                          failure: @escaping (Error) -> Void) {
        guard self.success else {
            failure(NSError())
            return
        }
        var response = ValidateDomainContactInformationResponse()
        response.success = true
        success(response)

    }

    func getDomainContactInformation(success: @escaping (DomainContactInformation) -> Void,
                                     failure: @escaping (Error) -> Void) {
        guard self.success else {
            failure(NSError())
            return
        }
        if emptyPrefillData {
            let contactInformation = DomainContactInformation()
            success(contactInformation)
        } else {
            var contactInformation = DomainContactInformation()
            contactInformation.firstName = "First"
            contactInformation.lastName = "Last"
            success(contactInformation)
        }
    }

    func getSupportedCountries(success: @escaping ([Country]) -> Void,
                               failure: @escaping (Error) -> Void) {
        guard self.success else {
            failure(NSError())
            return
        }
        let country1 = Country()
        country1.code = "TR"
        country1.name = "Turkey"
        let country2 = Country()
        country2.code = "US"
        country2.name = "United States"
        success([country1, country2])
    }

    func getStates(for countryCode: String,
                   success: @escaping ([State]) -> Void,
                   failure: @escaping (Error) -> Void) {
        guard self.success else {
            failure(NSError())
            return
        }
        let state1 = State()
        state1.code = "AL"
        state1.name = "Alabama"
        let state2 = State()
        state2.code = "AK"
        state2.name = "Alaska"
        success([state1, state2])
    }
}
