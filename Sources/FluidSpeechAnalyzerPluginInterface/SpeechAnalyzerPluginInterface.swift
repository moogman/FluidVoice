import Foundation

public struct SpeechAnalyzerTranscriptionResult: Sendable {
    public let text: String
    public let confidence: Float

    public init(text: String, confidence: Float) {
        self.text = text
        self.confidence = confidence
    }
}

public protocol SpeechAnalyzerProvider: AnyObject {
    var name: String { get }
    var isAvailable: Bool { get }
    var isReady: Bool { get }

    func prepare(progressHandler: ((Double) -> Void)?) async throws
    func transcribe(_ samples: [Float]) async throws -> SpeechAnalyzerTranscriptionResult

    func modelsExistOnDisk() -> Bool
    func refreshModelsExistOnDiskAsync() async -> Bool

    func clearCache() async throws
}

public protocol SpeechAnalyzerPluginLogger: AnyObject {
    func debug(_ message: String, source: String)
    func info(_ message: String, source: String)
    func warning(_ message: String, source: String)
}

public extension SpeechAnalyzerProvider {
    func modelsExistOnDisk() -> Bool { false }
    func refreshModelsExistOnDiskAsync() async -> Bool { self.modelsExistOnDisk() }
    func clearCache() async throws {}
}

public protocol SpeechAnalyzerPluginEntryPoint: AnyObject {
    static func makeProvider(logSink: (any SpeechAnalyzerPluginLogger)?) -> (any SpeechAnalyzerProvider)?
}
