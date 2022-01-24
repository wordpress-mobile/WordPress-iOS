import Foundation
@testable import WordPress

fileprivate struct CartResponseMock: CartResponseProtocol {}

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

    private let validateDomainContactInformationSuccess: Bool
    private let validateDomainContactInformationResponseSuccess: Bool
    private let createShoppingCartSuccess: Bool
    private let redeemCartUsingCreditsSuccess: Bool
    private let changePrimaryDomainSuccess: Bool

    private let emptyPrefillData: Bool

    init(validateDomainContactInformationSuccess: Bool = true,
         validateDomainContactInformationResponseSuccess: Bool = true,
         createShoppingCartSuccess: Bool = true,
         emptyPrefillDataSuccess: Bool = true,
         redeemCartUsingCreditsSuccess: Bool = true,
         changePrimaryDomainSuccess: Bool = true,
         emptyPrefillData: Bool = false) {
        self.validateDomainContactInformationSuccess = validateDomainContactInformationSuccess
        self.validateDomainContactInformationResponseSuccess = validateDomainContactInformationResponseSuccess
        self.createShoppingCartSuccess = createShoppingCartSuccess
        self.redeemCartUsingCreditsSuccess = redeemCartUsingCreditsSuccess
        self.changePrimaryDomainSuccess = changePrimaryDomainSuccess
        self.emptyPrefillData = emptyPrefillData
    }

    func validateDomainContactInformation(contactInformation: [String: String],
                                          domainNames: [String],
                                          success: @escaping (ValidateDomainContactInformationResponse) -> Void,
                                          failure: @escaping (Error) -> Void) {
        guard validateDomainContactInformationSuccess else {
            failure(NSError())
            return
        }
        var response = ValidateDomainContactInformationResponse()
        response.success = validateDomainContactInformationResponseSuccess
        success(response)

    }

    func getDomainContactInformation(success: @escaping (DomainContactInformation) -> Void,
                                     failure: @escaping (Error) -> Void) {
        guard validateDomainContactInformationSuccess else {
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

    func getSupportedCountries(success: @escaping ([WPCountry]) -> Void,
                               failure: @escaping (Error) -> Void) {
        guard validateDomainContactInformationSuccess else {
            failure(NSError())
            return
        }
        let country1 = WPCountry()
        country1.code = "TR"
        country1.name = "Turkey"
        let country2 = WPCountry()
        country2.code = MockData.countryCode
        country2.name = MockData.countryName
        success([country1, country2])
    }

    func getStates(for countryCode: String,
                   success: @escaping ([WPState]) -> Void,
                   failure: @escaping (Error) -> Void) {
        guard validateDomainContactInformationSuccess else {
            failure(NSError())
            return
        }
        let state1 = WPState()
        state1.code = MockData.stateCode
        state1.name = MockData.stateName
        let state2 = WPState()
        state2.code = "AK"
        state2.name = "Alaska"
        success([state1, state2])
    }

    func purchaseDomainUsingCredits(
        siteID: Int,
        domainSuggestion: DomainSuggestion,
        domainContactInformation: [String: String],
        privacyProtectionEnabled: Bool,
        success: @escaping (String) -> Void,
        failure: @escaping (Error) -> Void) {

        createTemporaryDomainShoppingCart(siteID: siteID, domainSuggestion: domainSuggestion, privacyProtectionEnabled: privacyProtectionEnabled, success: { cart in
            self.redeemCartUsingCredits(cart: cart, domainContactInformation: domainContactInformation, success: {
                success(domainSuggestion.domainName)
            }, failure: failure)
        }, failure: failure)
    }

    func createTemporaryDomainShoppingCart(siteID: Int,
                                           domainSuggestion: DomainSuggestion,
                                           privacyProtectionEnabled: Bool,
                                           success: @escaping (CartResponseProtocol) -> Void,
                                           failure: @escaping (Error) -> Void) {
        guard createShoppingCartSuccess else {
            failure(NSError())
            return
        }
        let response = CartResponseMock()
        success(response)
    }

    func createPersistentDomainShoppingCart(siteID: Int,
                                            domainSuggestion: DomainSuggestion,
                                            privacyProtectionEnabled: Bool,
                                            success: @escaping (CartResponseProtocol) -> Void,
                                            failure: @escaping (Error) -> Void) {
        guard createShoppingCartSuccess else {
            failure(NSError())
            return
        }
        let response = CartResponseMock()
        success(response)
    }

    func redeemCartUsingCredits(cart: CartResponseProtocol,
                                domainContactInformation: [String: String],
                                success: @escaping () -> Void,
                                failure: @escaping (Error) -> Void) {
        guard redeemCartUsingCreditsSuccess else {
            failure(NSError())
            return
        }
        success()
    }

    func setPrimaryDomain(siteID: Int,
                          domain: String,
                          success: @escaping () -> Void,
                          failure: @escaping (Error) -> Void) {
        guard changePrimaryDomainSuccess else {
            failure(NSError())
            return
        }
        success()
    }
}
