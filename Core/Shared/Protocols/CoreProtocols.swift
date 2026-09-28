import Foundation

public protocol IdentifiableEntity: Identifiable, Sendable where ID == String {}
public protocol Timestamped {
    var dateAdded: Date { get }
    var dateModified: Date { get }
}
