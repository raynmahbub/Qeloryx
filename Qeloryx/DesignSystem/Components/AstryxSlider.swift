// QELORYX — DesignSystem
// AstryxSlider.swift

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

public struct AstryxSlider: View {
    
    @Binding var value: Double
    let range: ClosedRange<Double>
    let onEditingChanged: (Bool) -> Void
    
    @State private var isEditing = false
    
    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self._value = value
        self.range = range
        self.onEditingChanged = onEditingChanged
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(AstryxColors.Semantic.surface)
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(AstryxColors.auroraBlue)
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 4)
                
                // Thumb
                Circle()
                    .fill(AstryxColors.iceWhite)
                    .frame(width: isEditing ? 20 : 16, height: isEditing ? 20 : 16)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - (isEditing ? 10 : 8))
                    .animation(AstryxAnimation.quick, value: isEditing)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isEditing {
                            isEditing = true
                            onEditingChanged(true)
                        }
                        let progress = min(max(0, gesture.location.x / geometry.size.width), 1)
                        value = range.lowerBound + Double(progress) * (range.upperBound - range.lowerBound)
                    }
                    .onEnded { _ in
                        isEditing = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 20)
    }
}

// MARK: - Seek Slider (with time labels)

public struct AstryxSeekSlider: View {
    @Binding var position: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    public init(position: Binding<TimeInterval>, duration: TimeInterval, onSeek: @escaping (TimeInterval) -> Void) {
        self._position = position
        self.duration = duration
        self.onSeek = onSeek
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            AstryxSlider(value: Binding(
                get: { duration > 0 ? position / duration : 0 },
                set: { newValue in position = newValue * duration }
            ), onEditingChanged: { editing in
                if !editing {
                    onSeek(position)
                }
            })
            
            HStack {
                Text(formattedTime(position))
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                Spacer()
                Text(formattedTime(duration))
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
        }
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
