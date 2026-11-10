// QELORYX — Views/Components/EmptyStates
// EmptyStateView.swift
// Standard empty state: icon, headline, supporting line, optional action.

import SwiftUI

public struct EmptyStateView: View {

    public struct Action {
        let title: String
        let handler: () -> Void

        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    private let systemImage: String
    private let headline: String
    private let message: String?
    private let action: Action?

    public init(systemImage: String, headline: String, message: String? = nil, action: Action? = nil) {
        self.systemImage = systemImage
        self.headline = headline
        self.message = message
        self.action = action
    }

    public var body: some View {
        VStack(spacing: AstryxSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            Text(headline)
                .font(AstryxTypography.Heading.h4)
                .foregroundColor(AstryxColors.Semantic.foreground)
            if let message {
                Text(message)
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .multilineTextAlignment(.center)
            }
            if let action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.borderedProminent)
                    .tint(AstryxColors.auroraBlue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
        .accessibilityElement(children: .combine)
    }
}
