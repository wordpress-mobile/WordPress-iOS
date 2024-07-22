import SwiftUI

extension ApplicationTokenItemView {
    class ViewModel: ObservableObject {
        @Published
        var deviceName: String {
            didSet {
                self.canSaveChanges = deviceName != originalDeviceName
            }
        }

        @Published
        var canSaveChanges: Bool = false

        @Published
        var isSavingChanges: Bool = false

        @Published
        var isConfirmingDeletion: Bool = false

        private let originalDeviceName: String

        init(deviceName: String) {
            self.deviceName = deviceName
            self.originalDeviceName = deviceName
        }

        func saveChanges() {
            withAnimation {
                self.isSavingChanges = true
            }

            Task {
                await MainActor.run {
                    withAnimation {
                        self.canSaveChanges = false
                    }
                }

                try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)

                await MainActor.run {
                    withAnimation {
                        self.isSavingChanges = false
                    }
                }
            }
        }

        func promptForDeleteConfirmation() {
            withAnimation {
                self.isConfirmingDeletion = true
            }
        }
    }
}
