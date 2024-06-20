/// Encapsulates logic to fetch blogging prompts from the remote endpoint.
///
open class BloggingPromptsServiceRemote: ServiceRemoteWordPressComREST {
    /// Used to format dates so the time information is omitted.
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()

    public enum RequestError: Error {
        case encodingFailure
    }

    /// Fetches a number of blogging prompts for the specified site.
    /// Note that this method hits wpcom/v2, which means the `WordPressComRestAPI` needs to be initialized with `LocaleKeyV2`.
    ///
    /// - Parameters:
    ///   - siteID: Used to check which prompts have been answered for the site with given `siteID`.
    ///   - number: The number of prompts to query. When not specified, this will default to remote implementation.
    ///   - fromDate: When specified, this will fetch prompts from the given date. When not specified, this will default to remote implementation.
    ///   - completion: A closure that will be called when the fetch request completes.
    open func fetchPrompts(for siteID: NSNumber,
                           number: Int? = nil,
                           fromDate: Date? = nil,
                           completion: @escaping (Result<[RemoteBloggingPrompt], Error>) -> Void) {
        let path = path(forEndpoint: "sites/\(siteID)/blogging-prompts", withVersion: ._2_0)
        let requestParameter: [String: AnyHashable] = {
            var params = [String: AnyHashable]()

            if let number = number, number > 0 {
                params["number"] = number
            }

            if let fromDate = fromDate {
                // convert to yyyy-MM-dd format, excluding the timezone information.
                // the date parameter doesn't need to be timezone-accurate since prompts are grouped by date.
                params["from"] = Self.dateFormatter.string(from: fromDate)
            }

            return params
        }()

        let decoder = JSONDecoder.apiDecoder
        // our API decoder assumes that we're converting from snake case.
        // revert it to default so the CodingKeys match the actual response keys.
        decoder.keyDecodingStrategy = .useDefaultKeys

        Task { @MainActor in
            await self.wordPressComRestApi
                .perform(
                    .get,
                    URLString: path,
                    parameters: requestParameter as [String: AnyObject],
                    jsonDecoder: decoder,
                    type: [String: [RemoteBloggingPrompt]].self
                )
                .map { $0.body.values.first ?? [] }
                .mapError { error -> Error in error.asNSError() }
                .execute(completion)
        }
    }

    /// Fetches the blogging prompts settings for a given site.
    ///
    /// - Parameters:
    ///   - siteID: The site ID for the blogging prompts settings.
    ///   - completion: Closure that will be called when the request completes.
    open func fetchSettings(for siteID: NSNumber, completion: @escaping (Result<RemoteBloggingPromptsSettings, Error>) -> Void) {
        let path = path(forEndpoint: "sites/\(siteID)/blogging-prompts/settings", withVersion: ._2_0)
        Task { @MainActor in
            await self.wordPressComRestApi.perform(.get, URLString: path, type: RemoteBloggingPromptsSettings.self)
                .map { $0.body }
                .mapError { error -> Error in error.asNSError() }
                .execute(completion)
        }
    }

    /// Updates the blogging prompts settings to remote.
    ///
    /// This will return an updated settings object if at least one of the fields is successfully modified.
    /// If nothing has changed, it will still be regarded as a successful operation; but nil will be returned.
    ///
    /// - Parameters:
    ///   - siteID: The site ID of the blogging prompts settings.
    ///   - settings: The updated settings to upload.
    ///   - completion: Closure that will be called when the request completes.
    open func updateSettings(for siteID: NSNumber,
                             with settings: RemoteBloggingPromptsSettings,
                             completion: @escaping (Result<RemoteBloggingPromptsSettings?, Error>) -> Void) {
        let path = path(forEndpoint: "sites/\(siteID)/blogging-prompts/settings", withVersion: ._2_0)
        var parameters = [String: AnyObject]()
        do {
            let data = try JSONEncoder().encode(settings)
            parameters = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject] ?? [:]
        } catch {
            completion(.failure(error))
            return
        }

        // The parameter shouldn't be empty at this point.
        // If by some chance it is, let's abort and return early. There could be something wrong with the parsing process.
        guard !parameters.isEmpty else {
            WPKitLogError("Error encoding RemoteBloggingPromptsSettings object: \(settings)")
            completion(.failure(RequestError.encodingFailure))
            return
        }

        wordPressComRESTAPI.post(path, parameters: parameters) { responseObject, _ in
            do {
                let data = try JSONSerialization.data(withJSONObject: responseObject)
                let response = try JSONDecoder().decode(UpdateBloggingPromptsSettingsResponse.self, from: data)
                completion(.success(response.updated))
            } catch {
                completion(.failure(error))
            }
        } failure: { error, _ in
            completion(.failure(error))
        }
    }
}

// MARK: - Private helpers

private extension BloggingPromptsServiceRemote {
    /// An intermediate object representing the response structure after updating the prompts settings.
    ///
    /// If there is at least one updated field, the remote will return the full `RemoteBloggingPromptsSettings` object in the `updated` key.
    /// Otherwise, if no fields are changed, the remote will assign an empty array to the `updated` key.
    struct UpdateBloggingPromptsSettingsResponse: Decodable {
        let updated: RemoteBloggingPromptsSettings?

        private enum CodingKeys: String, CodingKey {
            case updated
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // return nil when no fields are changed.
            if let _ = try? container.decode(Array.self, forKey: .updated) {
                self.updated = nil
                return
            }

            self.updated = try container.decode(RemoteBloggingPromptsSettings.self, forKey: .updated)
        }
    }
}
