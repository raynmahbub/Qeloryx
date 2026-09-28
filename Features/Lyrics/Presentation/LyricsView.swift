import SwiftUI

public struct LyricsView: View {
    let lyrics: AstryxLyrics?
    @State private var currentTime: TimeInterval = 0
    
    public init(lyrics: AstryxLyrics? = nil) {
        self.lyrics = lyrics
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(lyrics?.lines ?? [], id: \.id) { line in
                    Text(line.text)
                        .font(line.startTime <= currentTime ? AstryxTypography.Heading.h4 : AstryxTypography.Body.large)
                        .foregroundColor(line.startTime <= currentTime ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
                        .animation(.easeInOut, value: currentTime)
                }
            }
            .padding()
        }
    }
}
