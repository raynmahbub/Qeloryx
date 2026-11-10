// QELORYX — Views/Components/Sheets
// SheetScaffold.swift
// Standard modal sheet chrome: navigation bar, Done button, background.

import SwiftUI

public struct SheetScaffold<Content: View>: View {

    @Environment(\.dismiss) private var dismiss

    private let title: String
    private let content: () -> Content

    public init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                .background(AstryxColors.Semantic.background.ignoresSafeArea())
        }
    }
}
