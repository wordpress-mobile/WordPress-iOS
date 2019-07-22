@objc extension Blog {
    @objc var hasBusinessPlan: Bool {
        return [1008, // 1y Business Plan
                1018, // Month-to-Month Business Plan,
                1028] // 2y Business Plan
        .contains(planID?.intValue)
    }

    @objc var hasBloggerPlan: Bool {
        return [1010, // 1y Blogger Plan,
                1030] // 2y Blogger Plan
        .contains(planID?.intValue)
    }

    @objc var hasEcommercePlan: Bool {
        return [1011, // 1y Ecommerce Plan
                1031] // 2y Ecommerce Plan
        .contains(planID?.intValue)
    }
}
