// QELORYX — DownloadEngine
// DownloadSessionProtocol.swift
// QEL-041 — Abstraction for Platform download session to respect layer isolation

import Foundation

public protocol DownloadSessionDelegate: AnyObject, Sendable {
    func downloadDidProgress(taskID: String, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpected: Int64)
    func downloadDidComplete(taskID: String, location: URL)
    func downloadDidFail(taskID: String, error: Error, resumeData: Data?)
}

public protocol DownloadSessionProtocol: Sendable {
    var delegate: DownloadSessionDelegate? { get set }
    func startDownload(taskID: String, from url: URL, resumeData: Data?)
    func pauseDownload(taskID: String, completion: @escaping (Data?) -> Void)
    func cancelDownload(taskID: String)
    func checkDiskSpace(requiredBytes: Int64) -> Bool
}
