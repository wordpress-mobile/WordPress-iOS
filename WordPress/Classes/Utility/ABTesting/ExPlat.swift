import Foundation

class ExPlat: ABTesting {
    let service: ExPlatService

    init(service: ExPlatService = ExPlatService.withDefaultApi()) {
        self.service = service
    }

    func refresh(completion: (() -> Void)? = nil) {
        service.getAssignments { assignments in
            guard let assignments = assignments else {
                completion?()
                return
            }

            let validVariations = assignments.variations.filter { $0.value != nil }
            UserDefaults.standard.setValue(validVariations, forKey: "ab-testing-assignments")
            completion?()
        }
    }

    func experiment(_ name: String) -> Variation {
        guard let assignments = UserDefaults.standard.object(forKey: "ab-testing-assignments") as? [String: String?],
              case let variation?? = assignments[name] else {
            return .unknown
        }

        switch variation {
        case "control":
            return .control
        case "treatment":
            return .treatment
        default:
            return .other(variation)
        }
    }
}
