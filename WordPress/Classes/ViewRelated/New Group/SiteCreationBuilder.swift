// Tracks data state shared between Site Creation Wizard Steps
final class SiteCreationBuilder {
    var segment: SiteSegment?


    /// Generates the final object that will be posted to the backend
    ///
    /// - Returns: an Encodable object
    func build() -> SiteCreationOutput {
        return SiteCreationOutput()
    }
}
