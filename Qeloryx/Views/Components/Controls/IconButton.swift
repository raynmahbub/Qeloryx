// QELORYX — Views/Components/Controls
// IconButton.swift
// Circular icon button with a mandatory accessibility label.

import SwiftUI

public struct IconButton: View {

    private let systemImage: String
    private let label: String
    private let size: CGFloat
    private let action: () -> Void

    public init(systemImage: String, label: String, size: CGFloat = 36, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.label = label
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundColor(AstryxColors.Semantic.foreground)
                .frame(width: size, height: size)
                .background(AstryxColors.Semantic.surface.opacity(0.6))
                .clipShape(Circle())
        }
        .accessibilityLabel(label)
    }
}
