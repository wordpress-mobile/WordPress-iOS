import Foundation

class PlanFeaturesRemote: ServiceRemoteWordPressComREST {

    enum Error: ErrorType {
        case DecodeError
    }

    private var cacheDate: NSDate?
    private let languageDatabase = WordPressComLanguageDatabase()
    private var cacheFilename: String {
        let locale = languageDatabase.deviceLanguage.slug
        return "plan-features-\(locale).json"
    }

    func getPlanFeatures(success: PlanFeatures -> Void, failure: ErrorType -> Void) {
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
            self?.cacheDate = NSDate()

            success(planFeatures)
            }, failure: failure)
    }

    private var _planFeatures: PlanFeatures?
    private var inMemoryPlanFeatures: PlanFeatures? {
        get {
            // If we have something in memory and it's less than a day old, return it.
            if let planFeatures = _planFeatures,
                let cacheDate = cacheDate where
                cacheDateIsValid(cacheDate) {
                return planFeatures
            }

            return nil
        }

        set {
            _planFeatures = newValue
        }
    }

    private func cachedPlanFeatures() -> PlanFeatures? {
        guard let (planFeatures, _) = cachedPlanFeaturesWithDate() else { return nil}

        return planFeatures
    }

    /// - Returns: An optional tuple containing a collection of cached plan features and the date when they were fetched
    private func cachedPlanFeaturesWithDate() -> (PlanFeatures, NSDate)? {
        guard let cacheFileURL = cacheFileURL,
            let path = cacheFileURL.path,
            let attributes = try? NSFileManager.defaultManager().attributesOfItemAtPath(path),
            let modificationDate = attributes[NSFileModificationDate] as? NSDate where cacheDateIsValid(modificationDate) else { return nil }

        guard let response = NSData(contentsOfURL: cacheFileURL),
            let json = try? NSJSONSerialization.JSONObjectWithData(response, options: []),
            let planFeatures = try? mapPlanFeaturesResponse(json) else { return nil }

        return (planFeatures, modificationDate)
    }

    private func cacheDateIsValid(date: NSDate) -> Bool {
        return NSCalendar.currentCalendar().isDateInToday(date)
    }

    private func fetchPlanFeatures(success: PlanFeatures -> Void, failure: ErrorType -> Void) {
        let endpoint = "plans/features"
        let path = pathForEndpoint(endpoint, withVersion: .Version_1_2)
        let locale = languageDatabase.deviceLanguage.slug
        let parameters = ["locale": locale]

        wordPressComRestApi.GET(path,
                parameters: parameters,
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

    private var cacheFileURL: NSURL? {
        guard let cacheDirectory = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first else { return nil }

        return cacheDirectory.URLByAppendingPathComponent(cacheFilename)
    }

    private func cacheResponseObject(responseObject: AnyObject) {
        let data = try? NSJSONSerialization.dataWithJSONObject(responseObject, options: NSJSONWritingOptions())
        guard let responseData = data else { return }
        guard let cacheFileURL = cacheFileURL else { return }

        responseData.writeToURL(cacheFileURL, atomically: true)
    }
}

private func mapPlanFeaturesResponse(response: AnyObject) throws -> PlanFeatures {
    guard let json = response as? [[String: AnyObject]] else {
        throw PlansRemote.Error.DecodeError
    }

    var features = [PlanID: [PlanFeature]]()
    for featureDetails in json {

        guard let slug = featureDetails["product_slug"] as? String,
            let title = featureDetails["title"] as? String,
            var description = featureDetails["description"] as? String,
            let iconURLString = featureDetails["icon"] as? String,
            let iconURL = NSURL(string: iconURLString),
            let planDetails = featureDetails["plans"] as? [String: AnyObject] else { throw PlansRemote.Error.DecodeError }

        for (planID, planInfo) in planDetails {
            guard let planID = Int(planID) else { throw PlansRemote.Error.DecodeError }

            if features[planID] == nil {
                features[planID] = [PlanFeature]()
            }

            if let planInfo = planInfo as? [String: String],
                let planSpecificDescription = planInfo["description"] {
                description = planSpecificDescription
            }

            features[planID]?.append(PlanFeature(slug: slug, title: title, description: description, iconURL: iconURL))
        }
    }

    return features
}
