import SwiftUI

struct FilterCompactDatePicker: View {
    private let title: String
    @Binding private var selection: Date?
    private let range: ClosedRange<Date>
    private let components: DatePickerComponents

    init(_ title: String,
         selection: Binding<Date?>,
         in range: ClosedRange<Date> = Date.distantPast...Date.distantFuture,
         components: DatePickerComponents = [.date, .hourAndMinute]) {
        self.title = title
        self._selection = selection
        self.range = range
        self.components = components
    }

    var body: some View {
        FilterCompactButton(title, selection: $selection) {
            let binding = Binding(get: { self.selection ?? Date() }, set: { self.selection = $0 })
            let picker = DatePicker(title, selection: binding, in: range, displayedComponents: components)
                .datePickerStyle(.graphical)

            if #available(iOS 16.4, *) {
                picker
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .frame(width: 360)
                    .presentationCompactAdaptation(.popover)
            } else {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    NavigationView {
                        FilterCompactDatePickerCompatibilityView {
                            VStack {
                                picker
                                    .padding(.horizontal, 8)
                                Spacer()
                            }
                        }
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                    }
                } else {
                    picker.frame(width: 360)
                }
            }
        } label: { value in
            Text(string(from: value))
        }
    }

    private func string(from date: Date) -> String {
        let formatter = DateFormatter()
        if components.contains(.date) {
            formatter.dateStyle = .short
        }
        if components.contains(.hourAndMinute) {
            formatter.timeStyle = .short
        }
        return formatter.string(from: date)
    }
}

private struct FilterCompactDatePickerCompatibilityView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        content()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Done", comment: "A done button")) {
                        dismiss()
                    }
                }
            }
    }
}

#Preview {
    FilterCompactDatePickerPreview()
}

private struct FilterCompactDatePickerPreview: View {
    @State var selection: Date?

    var body: some View {
        VStack {
            FilterCompactDatePicker("Start Date", selection: $selection)
            Spacer()
        }
    }
}
