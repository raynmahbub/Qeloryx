// QELORYX — DesignSystem
// AstryxSheet.swift

import SwiftUI

public struct AstryxSheet<Content: View>: View {
    
    let content: Content
    @Environment(\.dismiss) private var dismiss
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.Semantic.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(AstryxColors.Semantic.foregroundTertiary)
                    .frame(width: 36, height: 5)
                    .padding(.top, AstryxSpacing.sm)
                    .padding(.bottom, AstryxSpacing.md)
                
                content
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.sheet))
    }
}

// MARK: - Sheet Detents

public extension View {
    func astrixSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.sheet(isPresented: isPresented) {
            AstryxSheet(content: content)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden) // We have custom indicator
                .presentationBackground(.ultraThinMaterial)
        }
    }
}
