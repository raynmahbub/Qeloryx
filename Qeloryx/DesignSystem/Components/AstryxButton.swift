// QELORYX — DesignSystem
// AstryxButton.swift
// Premium button with haptic feedback

#if canImport(QeloryxCore)
import QeloryxCore
#endif

#if canImport(UIKit)
import UIKit
#endif

import SwiftUI

public enum AstryxButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive
}

public enum AstryxButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }
    
    var font: Font {
        switch self {
        case .small: return AstryxTypography.Label.small
        case .medium: return AstryxTypography.Label.medium
        case .large: return AstryxTypography.Label.large
        }
    }
}

public struct AstryxButton: View {
    
    let title: String
    let style: AstryxButtonStyle
    let size: AstryxButtonSize
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    public init(
        title: String,
        style: AstryxButtonStyle = .primary,
        size: AstryxButtonSize = .medium,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            // Haptic feedback for premium feeling (iOS only)
            #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
            action()
        }) {
            HStack(spacing: AstryxSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                    }
                    Text(title)
                        .font(size.font)
                }
            }
            .foregroundColor(foregroundColor)
            .frame(height: size.height)
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .padding(.horizontal, AstryxSpacing.lg)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: AstryxCornerRadius.button)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return AstryxColors.iceWhite
        case .secondary: return AstryxColors.Semantic.foreground
        case .ghost: return AstryxColors.Semantic.foregroundSecondary
        case .destructive: return AstryxColors.Semantic.error
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return AstryxColors.auroraBlue
        case .secondary: return AstryxColors.Semantic.surface
        case .ghost: return Color.clear
        case .destructive: return AstryxColors.Semantic.error.opacity(0.15)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary: return Color.clear
        case .secondary: return AstryxColors.Semantic.border
        case .ghost: return Color.clear
        case .destructive: return AstryxColors.Semantic.error.opacity(0.3)
        }
    }
}

#if DEBUG
struct AstryxButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            AstryxButton(title: "Play", style: .primary, icon: "play.fill") {}
            AstryxButton(title: "Add to Queue", style: .secondary, icon: "plus") {}
            AstryxButton(title: "Cancel", style: .ghost) {}
            AstryxButton(title: "Delete", style: .destructive, icon: "trash") {}
        }
        .padding()
        .background(AstryxColors.midnight)
        .previewLayout(.sizeThatFits)
    }
}
#endif
