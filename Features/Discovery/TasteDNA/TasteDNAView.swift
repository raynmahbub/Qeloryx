import SwiftUI

public struct TasteDNAView: View {
    public init() {}
    public var body: some View {
        VStack {
            Text("Taste DNA").font(AstryxTypography.Heading.h2)
            Text("Live evolving listening profile").font(AstryxTypography.Body.medium)
            // Placeholder for Taste DNA visualization: Indie Rock Lo-Fi Jazz etc.
            HStack {
                ForEach(["Indie", "Rock", "Lo-Fi", "Jazz"], id: \.self) { genre in
                    Text(genre).padding(8).background(AstryxColors.auroraBlue.opacity(0.2)).clipShape(Capsule())
                }
            }
        }
    }
}
