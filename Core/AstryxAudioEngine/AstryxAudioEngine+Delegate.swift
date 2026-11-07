// QELORYX — AstryxAudioEngine
// AstryxAudioEngine+Delegate.swift
//
// Adapter delegate callbacks and the system remote-command handler.
// BUG-16: remote commands only report success once the engine has accepted the
// work, so Control Center cannot drift out of sync with the app.

import Foundation

#if canImport(MediaPlayer) && canImport(UIKit)
import MediaPlayer
#endif

extension AstryxAudioEngine: AVFoundationAdapterDelegate {

    public func adapterDidFinishPlaying() {
        Task { try? await self.next() }
    }

    public func adapterDidFail(error: Error) {
        fail(trackID: playbackState.currentTrackID, error: error)
    }

    public func adapterTimeDidUpdate(time: TimeInterval) {
        // The position clock owns progress; periodic adapter callbacks are
        // intentionally ignored to keep a single source of truth.
    }

    public func adapterDidChangeStatus(isReady: Bool) {
        // Loading completion is inferred from `load(url:)` returning plus the
        // adapter's first successful `isPlaying()` report.
        if !isReady, case .playing(let id, _, _) = playbackState {
            fail(trackID: id, error: PlaybackError.loadFailed(trackID: id, reason: "item is not ready"))
        }
    }
}

// MARK: - Remote commands

#if canImport(MediaPlayer) && canImport(UIKit)

final class RemoteCommandHandler: NowPlayingCommandHandler {
    private weak var engine: AstryxAudioEngine?

    init(engine: AstryxAudioEngine) {
        self.engine = engine
    }

    func handlePlay() -> MPRemoteCommandHandlerStatus {
        dispatch { try await $0.play(trackID: nil) }
    }

    func handlePause() -> MPRemoteCommandHandlerStatus {
        dispatch { try await $0.handle(command: .pause) }
    }

    func handleNext() -> MPRemoteCommandHandlerStatus {
        dispatch { try await $0.handle(command: .next) }
    }

    func handlePrevious() -> MPRemoteCommandHandlerStatus {
        dispatch { try await $0.handle(command: .previous) }
    }

    func handleSeek(to time: TimeInterval) -> MPRemoteCommandHandlerStatus {
        if time == -1 {
            return dispatch { try await $0.handle(command: .seekForward()) }
        } else if time == -2 {
            return dispatch { try await $0.handle(command: .seekBackward()) }
        }
        return dispatch { try await $0.handle(command: .seek(to: time)) }
    }

    func handleTogglePlayPause() -> MPRemoteCommandHandlerStatus {
        dispatch { try await $0.handle(command: .togglePlayPause) }
    }

    /// Runs the command and reports what actually happened.
    ///
    /// BUG-16: this used to spawn a detached `Task` and return `.success`
    /// immediately, so Control Center and the lock screen showed a seek or skip
    /// that may have thrown. The handlers are invoked off the main thread by
    /// MediaPlayer, so blocking on the transport work here is safe and makes the
    /// returned status truthful.
    private func dispatch(
        _ work: @escaping (AstryxAudioEngine) async throws -> Void
    ) -> MPRemoteCommandHandlerStatus {
        guard let engine else { return .commandFailed }
        guard !engine.currentQueue.isEmpty || engine.playbackState.currentTrackID != nil else {
            return .noSuchContent
        }
        let result = Self.runAndWait { try await work(engine) }
        switch result {
        case .success:
            return .success
        case .noSuchContent:
            return .noSuchContent
        case .failed(let error):
            engine.publishError(error, context: "remote-command")
            return .commandFailed
        }
    }

    /// File-private (not `private`) so `OutcomeBox` can carry it.
    enum CommandOutcome {
        case success
        case noSuchContent
        case failed(Error)
    }

    /// Bridges the async transport work into the synchronous handler signature
    /// without lying about the result.
    static func runAndWait(
        _ work: @escaping () async throws -> Void
    ) -> CommandOutcome {
        let semaphore = DispatchSemaphore(value: 0)
        let box = OutcomeBox()
        Task {
            do {
                try await work()
                box.set(.success)
            } catch let error as PlaybackError {
                if case .trackNotResolved = error {
                    box.set(.noSuchContent)
                } else {
                    box.set(.failed(error))
                }
            } catch {
                box.set(.failed(error))
            }
            semaphore.signal()
        }
        // Remote commands are latency-sensitive but must never hang the media
        // daemon; 10 s is far beyond any local transport operation.
        if semaphore.wait(timeout: .now() + 10) == .timedOut {
            return .failed(PlaybackError.commandTimedOut)
        }
        return box.value ?? .failed(PlaybackError.commandTimedOut)
    }
}

/// Thread-safe carrier for a remote command's outcome across the semaphore
/// boundary in `RemoteCommandHandler.runAndWait`.
private final class OutcomeBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: RemoteCommandHandler.CommandOutcome?

    var value: RemoteCommandHandler.CommandOutcome? {
        lock.lock(); defer { lock.unlock() }
        return _value
    }

    func set(_ outcome: RemoteCommandHandler.CommandOutcome) {
        lock.lock()
        _value = outcome
        lock.unlock()
    }
}

#else

final class RemoteCommandHandler: NowPlayingCommandHandler {
    private weak var engine: AstryxAudioEngine?

    init(engine: AstryxAudioEngine) {
        self.engine = engine
    }

    func handlePlay() -> Int { 0 }
    func handlePause() -> Int { 0 }
    func handleNext() -> Int { 0 }
    func handlePrevious() -> Int { 0 }
    func handleSeek(to time: TimeInterval) -> Int { 0 }
    func handleTogglePlayPause() -> Int { 0 }
}

#endif
