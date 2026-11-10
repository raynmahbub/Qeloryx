// QELORYX — Views/Components/Cards
// CardView.swift
// A thin composition wrapper over the design-system card: consistent corner
// radius, background and elevation for feature-level content.

import SwiftUI

public struct CardView<Content: View>: View {

    private let style: AstryxCardStyle
    private let content: () -> Content

    public init(style: AstryxCardStyle = .album, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.content = content
    }

    public var body: some View {
        AstryxCard(style: style) {
            content()
        }
    }
}
