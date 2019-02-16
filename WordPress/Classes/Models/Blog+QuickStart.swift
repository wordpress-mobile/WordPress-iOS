/// This extension contains all the methods for working with QuickStartTourStates
@nonobjc
extension Blog {
    public var completedQuickStartTours: [QuickStartTourState]? {
        return quickStartTours?.filter { $0.completed }
    }

    public var skippedQuickStartTours: [QuickStartTourState]? {
        return quickStartTours?.filter { $0.skipped }
    }

    public func skipTour(_ tourID: String) {
        let tourState = findOrCreate(tour: tourID)
        tourState.skipped = true

        let context = managedObjectContext ?? ContextManager.sharedInstance().mainContext
        ContextManager.sharedInstance().saveContextAndWait(context)
    }

    public func completeTour(_ tourID: String) {
        let tourState = findOrCreate(tour: tourID)
        tourState.completed = true

        let context = managedObjectContext ?? ContextManager.sharedInstance().mainContext
        ContextManager.sharedInstance().saveContextAndWait(context)
    }

    public func removeAllTours() {
        guard let quickStartTours = quickStartTours else {
            return
        }

        let context = managedObjectContext ?? ContextManager.sharedInstance().mainContext

        quickStartTours.forEach {
            context.delete($0)
        }
        ContextManager.sharedInstance().saveContextAndWait(context)
    }

    public func tourState(for tourID: String) -> QuickStartTourState? {
        return quickStartTours?.filter { $0.tourID == tourID }.first
    }

    func findOrCreate(tour tourID: String) -> QuickStartTourState {
        guard let existingTourState = tourState(for: tourID) else {
            let context = managedObjectContext ?? ContextManager.sharedInstance().mainContext

            let newTourState = NSEntityDescription.insertNewObject(forEntityName: QuickStartTourState.entityName(), into: context) as! QuickStartTourState
            newTourState.blog = self
            newTourState.tourID = tourID
            return newTourState
        }

        return existingTourState
    }
}
