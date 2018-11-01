// Tracks data state shared between Site Creation Wizard Steps. I am not too fond of the name, but it kind of works for now.
final class SiteCreationBuilder {
    var segment: SiteSegment?


    /// Generates the final object that will be posted to the backend
    ///
    /// - Returns: an Encodable object
    func build() -> SiteCreationOutput {
        return SiteCreationOutput()
    }
}
