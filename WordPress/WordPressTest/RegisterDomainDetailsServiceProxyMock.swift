import Foundation
@testable import WordPress

class RegisterDomainDetailsServiceProxyMock: RegisterDomainDetailsServiceProxyProtocol {

    enum MockData {
        static let firstName = "First"
        static let lastName = "Last"
        static let phone = "+90.2334432"
        static let phoneCountryCode = "90"
        static let phoneNumber = "2334432"
        static let city = "Istanbul"
        static let email = "pinar@yahoo.com"
        static let countryCode = "US"
        static let countryName = "United States"
        static let stateCode = "AL"
        static let stateName = "Alabama"
        static let address1 = "address1"
        static let organization = "organization"
        static let postalCode = "12345"
    }

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
            contactInformation.firstName = MockData.firstName
            contactInformation.lastName = MockData.lastName
            contactInformation.phone = MockData.phone
            contactInformation.city = MockData.city
            contactInformation.email = MockData.email
            contactInformation.countryCode = MockData.countryCode
            contactInformation.state = MockData.stateCode
            contactInformation.address1 = MockData.address1
            contactInformation.organization = MockData.organization
            contactInformation.postalCode = MockData.postalCode
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
        country2.code = MockData.countryCode
        country2.name = MockData.countryName
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
        state1.code = MockData.stateCode
        state1.name = MockData.stateName
        let state2 = State()
        state2.code = "AK"
        state2.name = "Alaska"
        success([state1, state2])
    }
}
