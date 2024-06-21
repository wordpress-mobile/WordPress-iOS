import Foundation

/// Class encapsualting all requests related to performing Automated Transfer operations.
public class AutomatedTransferService: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case decodingFailure
    }

    public enum AutomatedTransferEligibilityError: Error {
        case unverifiedEmail
        case excessiveDiskSpaceUsage
        case noBusinessPlan
        case VIPSite
        case notAdmin
        case notDomainOwner
        case noCustomDomain
        case greylistedSite
        case privateSite
        case unknown
    }

    public func checkTransferEligibility(siteID: Int,
                                         success: @escaping () -> Void,
                                         failure: @escaping (AutomatedTransferEligibilityError) -> Void) {
        let endpoint = "sites/\(siteID)/automated-transfers/eligibility"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRESTAPI.get(path, parameters: nil, success: { (responseObject, _) in
            guard let response = responseObject as? [String: AnyObject] else {
                failure(.unknown)
                return
            }

            guard let isEligible = response["is_eligible"] as? Bool, isEligible == true else {
                failure(self.eligibilityError(from: response))
                return
            }

            success()
        }, failure: { _, _ in
            failure(.unknown)
        })
    }

    public typealias AutomatedTransferInitationResponse = (transferID: Int, status: AutomatedTransferStatus)
    public func initiateAutomatedTransfer(siteID: Int,
                                          pluginSlug: String,
                                          success: @escaping (AutomatedTransferInitationResponse) -> Void,
                                          failure: @escaping (Error) -> Void) {

        let endpoint = "sites/\(siteID)/automated-transfers/initiate"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let payload = ["plugin": pluginSlug] as [String: AnyObject]

        wordPressComRESTAPI.post(path, parameters: payload, success: { (responseObject, _) in
            guard let response = responseObject as? [String: AnyObject] else {
                failure(ResponseError.decodingFailure)
                return
            }

            guard let transferID = response["transfer_id"] as? Int,
                  let status = response["status"] as? String,
                  let statusObject = AutomatedTransferStatus(status: status) else {
                failure(ResponseError.decodingFailure)
                return
            }

            success((transferID: transferID, status: statusObject))
        }) { (error, _) in
            failure(error)
        }

    }

    public func fetchAutomatedTransferStatus(siteID: Int,
                                             success: @escaping (AutomatedTransferStatus) -> Void,
                                             failure: @escaping (Error) -> Void) {

        let endpoint = "sites/\(siteID)/automated-transfers/status"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRESTAPI.get(path, parameters: nil, success: { (responseObject, _) in
            guard let response = responseObject as? [String: AnyObject] else {
                failure(ResponseError.decodingFailure)
                return
            }

            guard let status = response["status"] as? String,
                  let currentStep = response["step"] as? Int,
                  let totalSteps = response["total"] as? Int,
                  let statusObject = AutomatedTransferStatus(status: status, step: currentStep, totalSteps: totalSteps) else {
                    failure(ResponseError.decodingFailure)
                    return
            }

            success(statusObject)
        }) { (error, _) in
            failure(error)
        }

    }

    private func eligibilityError(from response: [String: AnyObject]) -> AutomatedTransferEligibilityError {
        guard let errors = response["errors"] as? [[String: AnyObject]],
            let errorType = errors.first?["code"] as? String else {
                // The API can potentially return multiple errors here. Since there isn't really an actionable
                // way for user to deal with multiple of them at once, we're just picking the first one.
                return .unknown
        }

        switch errorType {
        case "email_unverified":
            return .unverifiedEmail
        case "excessive_disk_space":
            return .excessiveDiskSpaceUsage
        case "no_business_plan":
            return .noBusinessPlan
        case "no_vip_sites":
            return .VIPSite
        case "non_admin_user":
            return .notAdmin
        case "not_domain_owner":
            return .notDomainOwner
        case "not_using_custom_domain":
            return .noCustomDomain
        case "site_graylisted":
            return .greylistedSite
        case "site_private":
            return .privateSite
        default:
            return .unknown
        }
    }

}
