// QELORYX — Views/Components/Artwork
// ArtworkThumbnail.swift
// Rounded thumbnail with a stable placeholder — used by lists and rows.

import SwiftUI

public struct ArtworkThumbnail: View {

    private let data: Data?
    private let size: CGFloat

    public init(data: Data?, size: CGFloat = 44) {
        self.data = data
        self.size = size
    }

    public var body: some View {
        AstryxArtwork(data: data, size: size, cornerRadius: AstryxCornerRadius.sm)
            .frame(width: size, height: size)
    }
}
