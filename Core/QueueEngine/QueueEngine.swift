// QELORYX — QueueEngine
// Per spec, QueueEngine is separate but for foundation it uses AstryxAudioEngine/Queue
// This file re-exports queue models and controller for modular boundary

import Foundation

// Re-export for external modules that expect QueueEngine
public typealias AstryxQueueEngine = AstryxQueueController
