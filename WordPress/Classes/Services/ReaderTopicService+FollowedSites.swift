import WordPressShared

extension ReaderTopicService {

    enum FollowedSitesError: Error {
        case unknown
    }

    @objc func fetchAllFollowedSites(success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())
        let pageSize: UInt = 25

        service.fetchFollowedSites(forPage: 1, number: pageSize) { totalSites, sites in
            guard let totalSites, let sites else {
                failure(nil)
                return
            }
            let totalPages = Int(ceil(Double(totalSites.intValue) / Double(pageSize)))
            WPAnalytics.subscriptionCount = totalSites.intValue

            guard totalPages > 1 else {
                self.mergeFollowedSites(sites, withSuccess: success)
                return
            }

            Task {
                await withTaskGroup(of: Result<[RemoteReaderSiteInfo], Error>.self) { taskGroup in
                    for page in 2...totalPages {
                        taskGroup.addTask {
                            return await self.fetchFollowedSites(service: service, page: UInt(page), number: pageSize)
                        }
                    }
                    var allSites = sites
                    for await result in taskGroup {
                        switch result {
                        case .success(let sites):
                            allSites.append(contentsOf: sites)
                        case .failure(let error):
                            DispatchQueue.main.async {
                                failure(error)
                            }
                            return
                        }
                    }
                    self.mergeFollowedSites(allSites, withSuccess: success)
                }
            }
        } failure: { error in
            failure(error)
        }
    }

    private func fetchFollowedSites(service: ReaderTopicServiceRemote, page: UInt, number: UInt) async -> Result<[RemoteReaderSiteInfo], Error> {
        return await withCheckedContinuation { continuation in
            service.fetchFollowedSites(forPage: page, number: number) { _, sites in
                continuation.resume(returning: .success(sites ?? []))
            } failure: { error in
                DDLogError("Error fetching page \(page) for followed sites: \(String(describing: error))")
                continuation.resume(returning: .failure(error ?? FollowedSitesError.unknown))
            }
        }
    }

    private func apiRequest() -> WordPressComRestApi {
        let token = self.coreDataStack.performQuery { context in
            try? WPAccount.lookupDefaultWordPressComAccount(in: context)?.authToken
        }

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress())
    }

}
