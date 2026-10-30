import DeclaredAgeRange
import UIKit

enum AgeRangeServiceResult: Equatable {
    case sharing(lowerBound: Int?)
    case declined
}

enum AgeRangeServiceError: Error {
    case unavailable
    case unknown
}

@MainActor
protocol AgeRangeServiceProtocol {
    func isEligible() async throws(AgeRangeServiceError) -> Bool
    func requestAgeRange(
        in viewController: UIViewController
    ) async throws(AgeRangeServiceError) -> AgeRangeServiceResult
}

struct AppleAgeRangeService: AgeRangeServiceProtocol {
    func isEligible() async throws(AgeRangeServiceError) -> Bool {
        guard #available(iOS 26.2, *) else {
            throw .unavailable
        }

        do {
            if #available(iOS 26.4, *) {
                return try await AgeRangeService.shared.requiredRegulatoryFeatures.contains(.declaredAgeRangeRequired)
            }
            return try await AgeRangeService.shared.isEligibleForAgeFeatures
        } catch {
            throw error is AgeRangeService.Error ? .unavailable : .unknown
        }
    }

    func requestAgeRange(
        in viewController: UIViewController
    ) async throws(AgeRangeServiceError) -> AgeRangeServiceResult {
        guard #available(iOS 26.2, *) else {
            throw .unavailable
        }

        let response: AgeRangeService.Response
        do {
            response = try await AgeRangeService.shared.requestAgeRange(ageGates: 13, in: viewController)
        } catch {
            throw error is AgeRangeService.Error ? .unavailable : .unknown
        }

        switch response {
        case .declinedSharing:
            return .declined
        case .sharing(let range):
            return .sharing(lowerBound: range.lowerBound)
        @unknown default:
            throw .unknown
        }
    }
}
