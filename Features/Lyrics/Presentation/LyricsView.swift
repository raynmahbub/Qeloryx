// QELORYX — Features — Lyrics
// LyricsView.swift
// QEL-032 Lyrics++ — Production with Synced, Karaoke, Translation-ready, Fullscreen

import SwiftUI

// MARK: - Main Lyrics View — QEL-032 Production

public struct LyricsView: View {
    
    @StateObject private var viewModel: LyricsViewModel
    @State private var showLanguagePicker = false
    
    private let track: AstryxTrack?
    
    public init(track: AstryxTrack? = nil, viewModel: LyricsViewModel = LyricsViewModel()) {
        self.track = track
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let lyrics = viewModel.lyrics, !lyrics.lines.isEmpty {
                contentView(lyrics: lyrics)
            } else if let error = viewModel.errorMessage {
                emptyView(message: error)
            } else {
                emptyView(message: "No lyrics available")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                menuButton
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            languagePickerSheet
        }
        .fullScreenCover(isPresented: $viewModel.isFullscreen) {
            fullscreenView
        }
        .onAppear {
            if let track = track {
                viewModel.loadLyrics(for: track)
            }
        }
        .onDisappear {
            viewModel.clear()
        }
    }
    
    // MARK: - Content
    
    private func contentView(lyrics: AstryxLyrics) -> some View {
        VStack(spacing: 0) {
            headerView(lyrics: lyrics)
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: displayModeSpacing) {
                        ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                            lyricLineView(line: line, index: index, isCurrent: viewModel.currentLineIndex == index)
                                .id(line.id)
                                .onTapGesture {
                                    viewModel.seekToLine(line)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .onChange(of: viewModel.currentLineIndex) { newIndex in
                    guard viewModel.autoScroll, let idx = newIndex, idx < lyrics.lines.count else { return }
                    let lineID = lyrics.lines[idx].id
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lineID, anchor: .center)
                    }
                }
            }
            
            bottomControls
        }
    }
    
    private var displayModeSpacing: CGFloat {
        switch viewModel.displayMode {
        case .karaoke: return 24
        case .synced: return 16
        case .plain: return 12
        case .fullscreen: return 32
        }
    }
    
    private func headerView(lyrics: AstryxLyrics) -> some View {
        VStack(spacing: 12) {
            HStack {
                if let title = lyrics.metadata.title {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AstryxTypography.Heading.h4)
                            .foregroundColor(AstryxColors.iceWhite)
                            .lineLimit(1)
                        if let artist = lyrics.metadata.artist {
                            Text(artist)
                                .font(AstryxTypography.Body.small)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                modeSelector
            }
            
            HStack(spacing: 8) {
                if lyrics.isKaraoke {
                    Label("Karaoke", systemImage: "mic.fill")
                        .font(AstryxTypography.Body.caption)
                        .foregroundColor(AstryxColors.auroraBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AstryxColors.auroraBlue.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                if !viewModel.availableLanguages.isEmpty {
                    Button {
                        showLanguagePicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "translate")
                            Text(viewModel.selectedLanguage.uppercased())
                            if viewModel.showTranslation {
                                Text("+ \(viewModel.translationLanguage.uppercased())")
                                    .foregroundColor(AstryxColors.auroraBlue)
                            }
                        }
                        .font(AstryxTypography.Body.caption)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    }
                }
                
                Spacer()
                
                Button {
                    viewModel.toggleAutoScroll()
                } label: {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                        .foregroundColor(viewModel.autoScroll ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AstryxColors.midnight.opacity(0.8))
    }
    
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach([LyricsDisplayMode.synced, LyricsDisplayMode.karaoke, LyricsDisplayMode.plain], id: \.self) { mode in
                Button {
                    viewModel.setDisplayMode(mode)
                } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.displayMode == mode ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
                        .frame(width: 32, height: 28)
                        .background(
                            viewModel.displayMode == mode ? AstryxColors.auroraBlue : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(2)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func lyricLineView(line: AstryxLyricLine, index: Int, isCurrent: Bool) -> some View {
        Group {
            if viewModel.displayMode == .karaoke && line.isKaraoke {
                karaokeLineView(line: line, isCurrent: isCurrent)
            } else {
                standardLineView(line: line, isCurrent: isCurrent)
            }
        }
    }
    
    private func standardLineView(line: AstryxLyricLine, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(line.text)
                .font(isCurrent ? AstryxTypography.Heading.h3 : AstryxTypography.Body.large)
                .fontWeight(isCurrent ? .bold : .regular)
                .foregroundColor(isCurrent ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
                .scaleEffect(isCurrent ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isCurrent)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.showTranslation, let translation = line.translation {
                Text(translation)
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.auroraBlue.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private func karaokeLineView(line: AstryxLyricLine, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 6) {
                ForEach(Array(line.words.enumerated()), id: \.element.id) { wordIndex, word in
                    let isWordCurrent = isCurrent && viewModel.currentWordIndex == wordIndex
                    let isWordPast = isCurrent && (viewModel.currentWordIndex ?? -1) > wordIndex
                    
                    Text(word.text)
                        .font(isCurrent ? AstryxTypography.Heading.h3 : AstryxTypography.Body.large)
                        .fontWeight(isWordCurrent ? .bold : .regular)
                        .foregroundColor(
                            isWordCurrent ? AstryxColors.auroraBlue :
                            isWordPast ? AstryxColors.iceWhite :
                            isCurrent ? AstryxColors.iceWhite.opacity(0.6) :
                            AstryxColors.Semantic.foregroundSecondary
                        )
                        .scaleEffect(isWordCurrent ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isWordCurrent)
                        .onTapGesture {
                            viewModel.seekToWord(word)
                        }
                }
            }
            
            if line.words.isEmpty {
                Text(line.text)
                    .font(isCurrent ? AstryxTypography.Heading.h3 : AstryxTypography.Body.large)
                    .fontWeight(isCurrent ? .bold : .regular)
                    .foregroundColor(isCurrent ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var bottomControls: some View {
        HStack(spacing: 16) {
            Text(viewModel.formattedTime(viewModel.currentTime))
                .font(AstryxTypography.Mono.small)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            
            Spacer()
            
            if viewModel.lyrics?.isSynced == true {
                Label("\(viewModel.lyrics?.lines.count ?? 0) lines", systemImage: "music.note.list")
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            
            Button {
                viewModel.isFullscreen = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AstryxColors.Semantic.backgroundSecondary.opacity(0.5))
    }
    
    private var menuButton: some View {
        Menu {
            Button { viewModel.setDisplayMode(.synced) } label: { Label("Synced Mode", systemImage: "music.note.list") }
            Button { viewModel.setDisplayMode(.karaoke) } label: { Label("Karaoke Mode", systemImage: "mic.fill") }
            Button { viewModel.setDisplayMode(.plain) } label: { Label("Plain Text", systemImage: "text.alignleft") }
            Divider()
            Button { viewModel.isFullscreen = true } label: { Label("Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right") }
            Button { viewModel.toggleAutoScroll() } label: { Label(viewModel.autoScroll ? "Disable Auto-scroll" : "Enable Auto-scroll", systemImage: "arrow.up.and.down.text.horizontal") }
            
            if !viewModel.availableLanguages.isEmpty {
                Divider()
                Menu("Translation") {
                    ForEach(viewModel.availableLanguages, id: \.self) { lang in
                        Button { viewModel.loadTranslation(language: lang) } label: { Text(lang.uppercased()) }
                    }
                    Button { viewModel.toggleTranslation() } label: { Text(viewModel.showTranslation ? "Hide Translation" : "Show Translation") }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(AstryxColors.auroraBlue)
            Text("Loading lyrics...")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func emptyView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary.opacity(0.5))
            Text(message)
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var languagePickerSheet: some View {
        NavigationView {
            List {
                ForEach(viewModel.availableLanguages, id: \.self) { lang in
                    Button {
                        viewModel.loadTranslation(language: lang)
                        showLanguagePicker = false
                    } label: {
                        HStack {
                            Text(lang.uppercased()).font(AstryxTypography.Body.medium)
                            Spacer()
                            if viewModel.translationLanguage == lang && viewModel.showTranslation {
                                Image(systemName: "checkmark").foregroundColor(AstryxColors.auroraBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showLanguagePicker = false }
                }
            }
        }
    }
    
    private var fullscreenView: some View {
        ZStack {
            AstryxColors.midnight.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { viewModel.isFullscreen = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AstryxColors.iceWhite)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Lyrics").font(AstryxTypography.Heading.h4).foregroundColor(AstryxColors.iceWhite)
                    Spacer()
                    Button { viewModel.toggleAutoScroll() } label: {
                        Image(systemName: "arrow.up.and.down.text.horizontal")
                            .foregroundColor(viewModel.autoScroll ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                if let lyrics = viewModel.lyrics {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 32) {
                                ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                                    let isCurrent = viewModel.currentLineIndex == index
                                    VStack(spacing: 12) {
                                        if viewModel.displayMode == .karaoke && line.isKaraoke {
                                            FlowLayout(spacing: 8) {
                                                ForEach(Array(line.words.enumerated()), id: \.element.id) { wordIndex, word in
                                                    let isWordCurrent = isCurrent && viewModel.currentWordIndex == wordIndex
                                                    Text(word.text)
                                                        .font(.system(size: isCurrent ? 32 : 24, weight: isWordCurrent ? .bold : .regular, design: .rounded))
                                                        .foregroundColor(
                                                            isWordCurrent ? AstryxColors.auroraBlue :
                                                            isCurrent ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary
                                                        )
                                                        .scaleEffect(isWordCurrent ? 1.15 : 1.0)
                                                        .animation(.easeInOut(duration: 0.2), value: isWordCurrent)
                                                }
                                            }
                                        } else {
                                            Text(line.text)
                                                .font(.system(size: isCurrent ? 32 : 24, weight: isCurrent ? .bold : .medium, design: .rounded))
                                                .foregroundColor(isCurrent ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
                                                .multilineTextAlignment(.center)
                                                .scaleEffect(isCurrent ? 1.05 : 1.0)
                                                .animation(.easeInOut(duration: 0.4), value: isCurrent)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .id(line.id)
                                    .onTapGesture { viewModel.seekToLine(line) }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 40)
                        }
                        .onChange(of: viewModel.currentLineIndex) { newIndex in
                            guard viewModel.autoScroll, let idx = newIndex else { return }
                            let lineID = lyrics.lines[idx].id
                            withAnimation(.easeInOut(duration: 0.6)) {
                                proxy.scrollTo(lineID, anchor: .center)
                            }
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    Text(viewModel.formattedTime(viewModel.currentTime))
                        .font(AstryxTypography.Mono.medium)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    Spacer()
                    Text("\(viewModel.currentLineIndex ?? 0 + 1) / \(viewModel.lyrics?.lines.count ?? 0)")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Flow Layout for Karaoke Words

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
