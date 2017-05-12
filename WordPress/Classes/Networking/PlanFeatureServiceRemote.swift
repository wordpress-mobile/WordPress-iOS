import Foundation

class PlanFeatureServiceRemote: ServiceRemoteWordPressComREST {

    enum ResponseError: Error {
        case decodingFailure
    }

    fileprivate var cacheDate: Date?
    fileprivate let languageDatabase = WordPressComLanguageDatabase()
    fileprivate var cacheFilename: String {
        let locale = languageDatabase.deviceLanguage.slug
        return "plan-features-\(locale).json"
    }

    func getPlanFeatures(_ success: @escaping (PlanFeatures) -> Void, failure: @escaping (Error) -> Void) {
        // First we'll try and return plan features from memory, then check our disk cache,
        // and finally hit the network if we don't have anything recent enough
        if let planFeatures = inMemoryPlanFeatures {
            success(planFeatures)
            return
        }

        // If we have features cached to disk, update the in-memory list and the cache date to match
        if let (planFeatures, date) = cachedPlanFeaturesWithDate() {
            inMemoryPlanFeatures = planFeatures
            cacheDate = date

            success(planFeatures)
            return
        }

        fetchPlanFeatures({ [weak self] planFeatures in
            self?.inMemoryPlanFeatures = planFeatures
            self?.cacheDate = Date()

            success(planFeatures)
            }, failure: failure)
    }

    fileprivate var _planFeatures: PlanFeatures?
    fileprivate var inMemoryPlanFeatures: PlanFeatures? {
        get {
            // If we have something in memory and it's less than a day old, return it.
            if let planFeatures = _planFeatures,
                let cacheDate = cacheDate,
                cacheDateIsValid(cacheDate) {
                return planFeatures
            }

            return nil
        }

        set {
            _planFeatures = newValue
        }
    }

    fileprivate func cachedPlanFeatures() -> PlanFeatures? {
        guard let (planFeatures, _) = cachedPlanFeaturesWithDate() else { return nil}

        return planFeatures
    }

    /// - Returns: An optional tuple containing a collection of cached plan features and the date when they were fetched
    fileprivate func cachedPlanFeaturesWithDate() -> (PlanFeatures, Date)? {
        guard let cacheFileURL = cacheFileURL,
            let attributes = try? FileManager.default.attributesOfItem(atPath: cacheFileURL.path),
            let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date, cacheDateIsValid(modificationDate) else { return nil }

        guard let response = try? Data(contentsOf: cacheFileURL),
            let json = try? JSONSerialization.jsonObject(with: response, options: []),
            let planFeatures = try? mapPlanFeaturesResponse(json as AnyObject) else { return nil }

        return (planFeatures, modificationDate)
    }

    fileprivate func cacheDateIsValid(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }

    fileprivate func fetchPlanFeatures(_ success: @escaping (PlanFeatures) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "plans/features"
        let path = self.path(forEndpoint: endpoint, with: .version_1_2)
        let locale = languageDatabase.deviceLanguage.slug
        let parameters = ["locale": locale]

        wordPressComRestApi.GET(path!,
                parameters: parameters as [String : AnyObject]?,
                success: {
                    [weak self] responseObject, _ in
                    do {
                        let planFeatures = try mapPlanFeaturesResponse(responseObject)
                        self?.cacheResponseObject(responseObject)
                        success(planFeatures)
                    } catch {
                        failure(error)
                    }
            }, failure: {
                error, _ in
                failure(error)
        })
    }

    fileprivate var cacheFileURL: URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }

        return cacheDirectory.appendingPathComponent(cacheFilename)
    }

    fileprivate func cacheResponseObject(_ responseObject: AnyObject) {
        let data = try? JSONSerialization.data(withJSONObject: responseObject, options: JSONSerialization.WritingOptions())
        guard let responseData = data else { return }
        guard let cacheFileURL = cacheFileURL else { return }

        try? responseData.write(to: cacheFileURL, options: [.atomic])
    }
}

private func mapPlanFeaturesResponse(_ response: AnyObject) throws -> PlanFeatures {
    guard let json = response as? [[String: AnyObject]] else {
        throw PlanFeatureServiceRemote.ResponseError.decodingFailure
    }

    var features = [PlanID: [PlanFeature]]()
    for featureDetails in json {

        guard let slug = featureDetails["product_slug"] as? String,
            let title = featureDetails["title"] as? String,
            var description = featureDetails["description"] as? String,
            let planDetails = featureDetails["plans"] as? [String: AnyObject] else { throw PlanServiceRemote.ResponseError.decodingFailure }

        for (planID, planInfo) in planDetails {
            guard let planID = Int(planID) else { throw PlanServiceRemote.ResponseError.decodingFailure }

            if features[planID] == nil {
                features[planID] = [PlanFeature]()
            }

            if let planInfo = planInfo as? [String: String],
                let planSpecificDescription = planInfo["description"] {
                description = planSpecificDescription
            }

            var iconURL: URL?
            if let iconURLString = featureDetails["icon"] as? String {
                iconURL = URL(string: iconURLString)
            }
            features[planID]?.append(PlanFeature(slug: slug, title: title, description: description, iconURL: iconURL))
        }
    }

    return features
}
