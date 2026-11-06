// QELORYX — DesignSystem
// AstryxNavigationBar.swift

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

public struct AstryxNavigationBar: View {
    
    let title: String
    let showBack: Bool
    let actions: [AstryxNavAction]
    let onBack: (() -> Void)?
    
    public init(title: String, showBack: Bool = false, actions: [AstryxNavAction] = [], onBack: (() -> Void)? = nil) {
        self.title = title
        self.showBack = showBack
        self.actions = actions
        self.onBack = onBack
    }
    
    public var body: some View {
        HStack {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AstryxColors.Semantic.foreground)
                }
            }
            
            Text(title)
                .font(AstryxTypography.Heading.h3)
                .foregroundColor(AstryxColors.Semantic.foreground)
            
            Spacer()
            
            HStack(spacing: AstryxSpacing.sm) {
                ForEach(actions) { action in
                    Button(action: action.action) {
                        Image(systemName: action.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AstryxColors.Semantic.foreground)
                    }
                }
            }
        }
        .padding(.horizontal, AstryxSpacing.screenPadding)
        .padding(.vertical, AstryxSpacing.sm)
        .background(.ultraThinMaterial)
        .background(AstryxColors.Semantic.background.opacity(0.8))
    }
}

public struct AstryxNavAction: Identifiable {
    public let id: String
    public let icon: String
    public let action: () -> Void
    
    public init(id: String = UUID().uuidString, icon: String, action: @escaping () -> Void) {
        self.id = id
        self.icon = icon
        self.action = action
    }
}

// MARK: - Large Title variant (artwork-aware per spec)

public struct AstryxLargeNavigationBar: View {
    let title: String
    let subtitle: String?
    
    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AstryxTypography.Heading.h1)
                .foregroundColor(AstryxColors.Semantic.foreground)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AstryxTypography.Body.medium)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AstryxSpacing.screenPadding)
        .padding(.vertical, AstryxSpacing.md)
    }
}
