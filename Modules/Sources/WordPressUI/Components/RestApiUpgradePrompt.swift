import SwiftUI

@available(iOS 16.4, *)
public struct RestApiUpgradePrompt: View {

    var didTapGetStarted: () -> Void
    var didTapLearnMore: () -> Void

    public init(didTapGetStarted: @escaping () -> Void, didTapLearnMore: @escaping () -> Void) {
        self.didTapGetStarted = didTapGetStarted
        self.didTapLearnMore = didTapLearnMore
    }

    public var body: some View {
        Color(.systemGroupedBackground).ignoresSafeArea().overlay {
            VStack {
                AccessibilityScrollView {
                    VStack(alignment: .leading) {
                        Text("Application Password Required")
                            .font(.largeTitle)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Application passwords are a more secure way to connect to your self-hosted site, and enable support for features like User Management.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }.padding()
                }
                Spacer()
                VStack {
                    Button(action: didTapGetStarted, label: {
                        HStack {
                            Spacer()
                            Text("Get Started")
                                .font(.headline)
                                .padding(.DS.Padding.half)
                            Spacer()
                        }
                    }).buttonStyle(.borderedProminent)

                    Button(action: didTapLearnMore, label: {
                        HStack {
                            Spacer()
                            Text("Learn More")
                                .font(.subheadline)
                                .underline()
                                .padding(.DS.Padding.half)
                            Spacer()
                        }
                    }).tint(.primary)
                }.padding()
            }
        }
    }
}

@available(iOS 16.4, *)
#Preview {
    RestApiUpgradePrompt {
        debugPrint("Tapped Get Started")
    } didTapLearnMore: {
        debugPrint("Tapped Learn More")
    }
}
