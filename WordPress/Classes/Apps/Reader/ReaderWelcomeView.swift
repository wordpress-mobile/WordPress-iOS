import ColorStudio
import UIKit
import SwiftUI
import WordPressUI

struct ReaderWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack {
                Text(SharedStrings.Reader.title)
                    .font(.make(.recoleta, size: 60, relativeTo: .largeTitle))
                    .padding(.top, 86)
                Text(Strings.subtitle)
                    .font(.make(.recoleta, textStyle: .body))
                Button(Strings.continueText) {
                    onContinue()
                }.buttonStyle(.primary)
                    .padding(.top, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Rectangle()
                    .fill(Color(CSColor.WordPressBlue.base))
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                stops: [
                                    .init(color: .white.opacity(0.0), location: 0.0),
                                    .init(color: .white.opacity(1.0), location: 0.5)
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .safeAreaInset(edge: .bottom) {
            Image("wp-logotype")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
        }
        .edgesIgnoringSafeArea(.top)
    }
}

private enum Strings {
    static let subtitle = NSLocalizedString("reader.welcome.subtitle", value: "Join the largest blogging community", comment: "Reader Welcome screen")
    static let continueText = NSLocalizedString("reader.welcome.continueText", value: "Continue with WordPress.com", comment: "Reader Welcome screen login button")
}

#Preview {
    ReaderWelcomeView(onContinue: {})
        .tint(AppColor.primary)
}
