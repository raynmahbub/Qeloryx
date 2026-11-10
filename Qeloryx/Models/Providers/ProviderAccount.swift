// QELORYX — Models/Providers
// ProviderAccount.swift
//
// An account reference only. Credentials never live in this model — they are
// stored via the platform keychain (see Services/Security/CredentialStore.swift)
// and referenced here by an opaque `credentialRef`.

import Foundation

public struct AstryxProviderAccount: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let providerID: AstryxProviderID
    public var displayName: String
    public var username: String?
    public var isActive: Bool
    public var createdAt: Date
    /// Opaque pointer into the credential store. Never the secret itself.
    public var credentialRef: String?

    public init(
        id: String = UUID().uuidString,
        providerID: AstryxProviderID,
        displayName: String,
        username: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        credentialRef: String? = nil
    ) {
        self.id = id
        self.providerID = providerID
        self.displayName = displayName
        self.username = username
        self.isActive = isActive
        self.createdAt = createdAt
        self.credentialRef = credentialRef
    }
}
