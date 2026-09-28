import SwiftUI

public struct DashboardView: View {
    public init() {}
    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(["Favorites", "Recent", "Downloads", "Mood", "Queue", "Vinyl"], id: \.self) { widget in
                    AstryxCard {
                        VStack {
                            Text(widget).font(AstryxTypography.Label.medium)
                            Image(systemName: "music.note").font(.largeTitle)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
    }
}
