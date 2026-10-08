import SwiftUI

final class TabBarState: ObservableObject {
    @Published var hidden = false
}

struct HidesTabBar: ViewModifier {
    @EnvironmentObject private var tabBar: TabBarState
    
    func body(content: Content) -> some View {
        content
            .onAppear { tabBar.hidden = true }
            .onDisappear { tabBar.hidden = false }
    }
}

extension View {
    func hidesTabBar() -> some View {
        modifier(HidesTabBar())
    }
}

struct BrickPushedScreen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.brickCanvas
                .ignoresSafeArea()
            content
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.brickInk)
                }
                .accessibilityIdentifier(AccessibilityID.navBack)
                .accessibilityLabel("Back")
            }
        }
        .hidesTabBar()
    }
}
