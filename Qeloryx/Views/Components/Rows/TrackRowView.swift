// QELORYX — Views/Components/Rows
// TrackRowView.swift
// The standard two-line track row used by search, history and queue screens.

import SwiftUI

public struct TrackRowView: View {

    private let title: String
    private let artist: String
    private let artworkData: Data?
    private let onTap: (() -> Void)?

    public init(title: String, artist: String, artworkData: Data? = nil, onTap: (() -> Void)? = nil) {
        self.title = title
        self.artist = artist
        self.artworkData = artworkData
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: AstryxSpacing.sm) {
                AstryxArtwork(data: artworkData, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AstryxTypography.Label.medium)
                        .foregroundColor(AstryxColors.Semantic.foreground)
                        .lineLimit(1)
                    Text(artist)
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), by \(artist)")
    }
}
