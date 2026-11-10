// QELORYX — Views/Components/Loading
// SkeletonView.swift
// Pulsing placeholder block shown while content loads. No spinner-on-everything.

import SwiftUI

public struct SkeletonView: View {

    @State private var isPulsing = false

    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = AstryxCornerRadius.sm) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AstryxColors.Semantic.surface)
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
            .accessibilityHidden(true)
    }
}
