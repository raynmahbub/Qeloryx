// QELORYX — Services/Security
// CredentialStore.swift
//
// Where provider credentials live. The app never stores secrets in its own
// files or UserDefaults; they go through the keychain (iOS) or this seam.
// `InMemoryCredentialStore` exists for previews and tests — it is not a
// persistence mechanism.
//
// NOTE: a Security.framework (SecItem*) backed implementation is the
// designated production adapter; it is deliberately not hand-rolled here yet.

import Foundation

public protocol CredentialStoring: Sendable {
    func save(_ secret: String, for ref: String) throws
    func read(ref: String) throws -> String?
    func contains(ref: String) -> Bool
    func delete(ref: String) throws
}

public enum CredentialStoreError: Error, Sendable, Equatable {
    case notFound(ref: String)
}

/// Volatile, process-local store. Never use for real credentials in a
/// shipping build.
public final class InMemoryCredentialStore: CredentialStoring, @unchecked Sendable {
    private var secrets: [String: String] = [:]
    private let lock = NSLock()

    public init() {}

    public func save(_ secret: String, for ref: String) throws {
        lock.lock(); defer { lock.unlock() }
        secrets[ref] = secret
    }

    public func read(ref: String) throws -> String? {
        lock.lock(); defer { lock.unlock() }
        return secrets[ref]
    }

    public func contains(ref: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return secrets[ref] != nil
    }

    public func delete(ref: String) throws {
        lock.lock(); defer { lock.unlock() }
        secrets.removeValue(forKey: ref)
    }
}
