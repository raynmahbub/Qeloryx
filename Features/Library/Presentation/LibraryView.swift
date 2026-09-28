import SwiftUI

public struct LibraryView: View {
    @State private var tracks: [AstryxTrack] = []
    @Environment(\.libraryEngine) private var libraryEngine
    
    public init() {}
    
    public var body: some View {
        List(tracks, id: \.id) { track in
            HStack {
                AstryxArtwork(data: track.artworkData, size: 48)
                VStack(alignment: .leading) {
                    Text(track.title).font(AstryxTypography.Label.medium)
                    Text(track.artist).font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
            }
        }
        .task {
            tracks = (try? await libraryEngine.fetchAllTracks()) ?? []
        }
    }
}
