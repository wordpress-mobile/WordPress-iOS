import Foundation
import Testing

extension Trait where Self == ConditionTrait {
    static var enabledOnCI: Self {
        .enabled(if: ProcessInfo.processInfo.environment["CI"] == "true", "Runs on CI")
    }
}
