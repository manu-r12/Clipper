//
//  MediaRemoteNowPlayingProvider.swift
//  Clipper
//
//  Mirrors Atoll's NowPlayingController pattern:
//  - Now-playing data read via Perl subprocess + MediaRemoteAdapter.framework (JSON stream)
//  - Commands (play/pause/seek) via direct MediaRemote function pointers

import AppKit
import Combine
import Foundation

// MARK: - Command function signatures (write-only side)

private typealias MRSendCommandFn     = @convention(c) (Int, AnyObject?) -> Void
private typealias MRSetElapsedTimeFn  = @convention(c) (Double) -> Void
private typealias MRSetShuffleModeFn  = @convention(c) (Int) -> Void

// MARK: - JSON payloads (mirrors Atoll's NowPlayingUpdate / NowPlayingPayload)

private struct NowPlayingUpdate: Codable {
    let payload: NowPlayingPayload
    let diff: Bool?
}

private struct NowPlayingPayload: Codable {
    let title: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let elapsedTime: Double?
    let artworkData: String?
    let timestamp: String?
    let playbackRate: Double?
    let playing: Bool?
    let shuffleMode: Int?
    let parentApplicationBundleIdentifier: String?
    let bundleIdentifier: String?
}

// MARK: - Pipe handler (mirrors Atoll's JSONLinesPipeHandler)

private actor JSONLinesPipeHandler {
    private let pipe = Pipe()
    private var buffer = ""

    func getPipe() -> Pipe { pipe }

    func readJSONLines<T: Decodable>(as type: T.Type, onLine: @escaping (T) async -> Void) async {
        let handle = pipe.fileHandleForReading
        while true {
            let data = await withCheckedContinuation { (continuation: CheckedContinuation<Data, Never>) in
                handle.readabilityHandler = { fh in
                    let d = fh.availableData
                    fh.readabilityHandler = nil
                    continuation.resume(returning: d)
                }
            }
            guard !data.isEmpty else { break }
            guard let chunk = String(data: data, encoding: .utf8) else { continue }
            buffer.append(chunk)
            while let range = buffer.range(of: "\n") {
                let line = String(buffer[..<range.lowerBound])
                buffer = String(buffer[range.upperBound...])
                guard !line.isEmpty,
                      let lineData = line.data(using: .utf8),
                      let decoded = try? JSONDecoder().decode(T.self, from: lineData)
                else { continue }
                await onLine(decoded)
            }
        }
    }

    nonisolated func close() {
        pipe.fileHandleForReading.readabilityHandler = nil
        try? pipe.fileHandleForReading.close()
        try? pipe.fileHandleForWriting.close()
    }
}

// MARK: - Provider

final class MediaRemoteNowPlayingProvider: NowPlayingProvider {

    private let subject = CurrentValueSubject<NowPlayingItem?, Never>(nil)
    var itemPublisher: AnyPublisher<NowPlayingItem?, Never> { subject.eraseToAnyPublisher() }

    // Command-only function pointers (loaded directly from MediaRemote).
    private let sendCommandFn: MRSendCommandFn?
    private let setElapsedTimeFn: MRSetElapsedTimeFn?
    private let setShuffleModeFn: MRSetShuffleModeFn?

    private var process: Process?
    private var pipeHandler: JSONLinesPipeHandler?
    private var streamTask: Task<Void, Never>?

    // Tracks last known state for diff merging.
    private var lastItem: NowPlayingItem?

    init?() {
        // Load MediaRemote just for the command function pointers.
        if let bundle = CFBundleCreate(
            kCFAllocatorDefault,
            NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
        ) {
            sendCommandFn = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString)
                .map { unsafeBitCast($0, to: MRSendCommandFn.self) }
            setElapsedTimeFn = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetElapsedTime" as CFString)
                .map { unsafeBitCast($0, to: MRSetElapsedTimeFn.self) }
            setShuffleModeFn = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetShuffleMode" as CFString)
                .map { unsafeBitCast($0, to: MRSetShuffleModeFn.self) }
        } else {
            sendCommandFn = nil
            setElapsedTimeFn = nil
            setShuffleModeFn = nil
        }

        Task { await self.startSubprocess() }
    }

    deinit {
        streamTask?.cancel()
        process?.terminate()
        pipeHandler?.close()
    }

    // MARK: - Commands

    func sendPlayPause()                            { sendCommandFn?(2, nil) }
    func sendNextTrack()                            { sendCommandFn?(4, nil) }
    func sendPreviousTrack()                        { sendCommandFn?(5, nil) }
    func sendSeek(to time: Double)                  { setElapsedTimeFn?(time) }
    func sendToggleShuffle(currentlyShuffled: Bool) { setShuffleModeFn?(currentlyShuffled ? 0 : 1) }

    // MARK: - Subprocess

    private func startSubprocess() async {
        guard
            let scriptURL = Bundle.main.url(forResource: "mediaremote-adapter", withExtension: "pl"),
            let frameworkPath = Bundle.main.resourceURL?
                .appendingPathComponent("MediaRemoteAdapter.framework")
                .path
        else {
            print("[MediaRemoteNowPlayingProvider] Could not find adapter script or framework in bundle")
            return
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        proc.arguments = [scriptURL.path, frameworkPath, "stream"]

        let handler = JSONLinesPipeHandler()
        proc.standardOutput = await handler.getPipe()

        let stderrPipe = Pipe()
        proc.standardError = stderrPipe
        stderrPipe.fileHandleForReading.readabilityHandler = { fh in
            let d = fh.availableData
            guard !d.isEmpty, let msg = String(data: d, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !msg.isEmpty else { return }
            print("[MediaRemoteAdapter stderr]: \(msg)")
        }

        self.process = proc
        self.pipeHandler = handler

        do {
            try proc.run()
        } catch {
            print("[MediaRemoteNowPlayingProvider] Failed to launch perl: \(error)")
            return
        }

        streamTask = Task { [weak self] in
            guard let self else { return }
            await handler.readJSONLines(as: NowPlayingUpdate.self) { [weak self] update in
                await self?.handleUpdate(update)
            }
        }
    }

    @MainActor
    private func handleUpdate(_ update: NowPlayingUpdate) {
        let p = update.payload
        let isDiff = update.diff ?? false
        let prev = lastItem

        let title = p.title ?? (isDiff ? prev?.title : nil) ?? ""
        let artist = p.artist ?? (isDiff ? prev?.artist : nil) ?? ""
        let duration = p.duration ?? (isDiff ? prev?.duration : nil) ?? 0
        let elapsed = p.elapsedTime ?? (isDiff ? prev?.elapsedTime : nil) ?? 0
        let rate = p.playbackRate ?? (isDiff ? prev?.playbackRate : nil) ?? 0
        let isPlaying  = p.playing     ?? (isDiff ? prev?.isPlaying  : nil) ?? false
        let isShuffled = (p.shuffleMode ?? (isDiff ? (prev?.isShuffled == true ? 1 : 0) : nil) ?? 0) != 0

        var timestamp = Date()
        if let ts = p.timestamp, let parsed = ISO8601DateFormatter().date(from: ts) {
            timestamp = parsed
        } else if isDiff, let prev {
            timestamp = prev.lastUpdated
        }

        var artwork: NSImage? = isDiff ? prev?.artwork : nil
        if let b64 = p.artworkData,
           let data = Data(base64Encoded: b64.trimmingCharacters(in: .whitespacesAndNewlines)) {
            artwork = NSImage(data: data)
        }

        guard !title.isEmpty else {
            subject.send(nil)
            lastItem = nil
            return
        }

        let appName = p.parentApplicationBundleIdentifier
            ?? p.bundleIdentifier
            ?? (isDiff ? prev?.appName : nil)
            ?? ""

        let item = NowPlayingItem(
            title: title,
            artist: artist,
            appName: appName,
            artwork: artwork,
            isPlaying: isPlaying,
            isShuffled: isShuffled,
            duration: duration,
            elapsedTime: elapsed,
            lastUpdated: timestamp,
            playbackRate: rate
        )
        lastItem = item
        subject.send(item)
    }
}
