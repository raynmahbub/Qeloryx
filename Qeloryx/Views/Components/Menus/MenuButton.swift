// QELORYX — Views/Components/Menus
// MenuButton.swift
// Standard overflow-style menu button with SF Symbol trigger.

import SwiftUI

public struct MenuButton<Content: View>: View {

    private let systemImage: String
    private let label: String
    private let content: () -> Content

    public init(systemImage: String = "ellipsis.circle", label: String = "More options", @ViewBuilder content: @escaping () -> Content) {
        self.systemImage = systemImage
        self.label = label
        self.content = content
    }

    public var body: some View {
        Menu {
            content()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(AstryxColors.Semantic.foreground)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel(label)
    }
}
