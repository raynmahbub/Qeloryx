// QELORYX — Views/Queue
// QueueView.swift
// The play queue: reorder, remove, clear, jump to a track. Reads the queue
// controller via `QueueViewModel`; engine remains the source of truth.

import SwiftUI

public struct QueueView: View {

    @StateObject private var viewModel: QueueViewModel

    public init(queueController: any QueueControllerProtocol, libraryEngine: any LibraryEngineProtocol) {
        _viewModel = StateObject(
            wrappedValue: QueueViewModel(queueController: queueController, libraryEngine: libraryEngine)
        )
    }

    public var body: some View {
        Group {
            if viewModel.isEmpty {
                emptyState
            } else {
                queueList
            }
        }
        .navigationTitle("Queue")
        .toolbar {
            if !viewModel.isEmpty {
                EditButton()
                Button("Clear", role: .destructive) {
                    Task { await viewModel.clear() }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var queueList: some View {
        List {
            ForEach(viewModel.items) { item in
                Button {
                    Task { await viewModel.jump(to: item) }
                } label: {
                    HStack(spacing: AstryxSpacing.sm) {
                        AstryxArtwork(data: viewModel.artworkData(for: item), size: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.title(for: item))
                                .font(AstryxTypography.Label.medium)
                                .foregroundColor(AstryxColors.Semantic.foreground)
                                .lineLimit(1)
                            Text(viewModel.artist(for: item))
                                .font(AstryxTypography.Body.small)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if viewModel.isCurrent(item) {
                            Image(systemName: "waveform")
                                .font(.caption)
                                .foregroundColor(AstryxColors.auroraBlue)
                                .accessibilityLabel("Now playing")
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                Task { await viewModel.remove(at: offsets) }
            }
            .onMove { source, destination in
                Task { await viewModel.move(from: source, to: destination) }
            }
        }
        .listStyle(.plain)
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
    }

    private var emptyState: some View {
        VStack(spacing: AstryxSpacing.md) {
            Image(systemName: "list.bullet")
                .font(.system(size: 40))
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            Text("Queue is empty")
                .font(AstryxTypography.Heading.h4)
                .foregroundColor(AstryxColors.Semantic.foreground)
            Text("Songs you play next will show up here.")
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
    }
}
