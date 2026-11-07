// QELORYX — Features/Lyrics
// LyricsView+Lines.swift
//
// Extracted from `LyricsView.swift` to keep that type under the 400-line
// `type_body_length` limit. These are rendering helpers only; all state stays
// on `LyricsView`.

import SwiftUI

extension LyricsView {
    func lyricLineView(line: AstryxLyricLine, index: Int, isCurrent: Bool) -> some View {
        Group {
            if viewModel.displayMode == .karaoke && line.isKaraoke {
                karaokeLineView(line: line, isCurrent: isCurrent)
            } else {
                standardLineView(line: line, isCurrent: isCurrent)
            }
        }
    }
    
    func standardLineView(line: AstryxLyricLine, isCurrent: Bool) -> some View {
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
    
    func karaokeLineView(line: AstryxLyricLine, isCurrent: Bool) -> some View {
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
    
    var bottomControls: some View {
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
    
    var menuButton: some View {
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
    
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(AstryxColors.auroraBlue)
            Text("Loading lyrics...")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func emptyView(message: String) -> some View {
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
    
    var languagePickerSheet: some View {
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
}
