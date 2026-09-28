import SwiftUI

public struct SpacesView: View {
    public init() {}
    public var body: some View {
        VStack {
            Text("Astryx Spaces").font(AstryxTypography.Heading.h2)
            Text("Shared Queue • DJ Handoff • Live Reactions • Future Voice Rooms").font(AstryxTypography.Body.small)
        }
    }
}
