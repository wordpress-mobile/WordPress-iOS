import Foundation

class ExPlat: ABTesting {
    let service: ExPlatService

    init(service: ExPlatService = ExPlatService.withDefaultApi()) {
        self.service = service
    }

    func refresh() {
        service.getAssignments { assignments in
            guard let assignments = assignments else {
                return
            }

            UserDefaults.standard.setValue(assignments.variations, forKey: "ab-testing-assignments")
        }
    }
}
