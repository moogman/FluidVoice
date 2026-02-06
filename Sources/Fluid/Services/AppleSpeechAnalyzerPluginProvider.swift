import FluidSpeechAnalyzerPluginInterface
import Foundation

protocol AsyncModelsExistOnDiskChecking {
    func refreshModelsExistOnDiskAsync() async -> Bool
}

final class AppleSpeechAnalyzerPluginProvider: TranscriptionProvider, AsyncModelsExistOnDiskChecking {
    private let pluginProvider: any SpeechAnalyzerProvider

    init(pluginProvider: any SpeechAnalyzerProvider) {
        self.pluginProvider = pluginProvider
    }

    var name: String { self.pluginProvider.name }
    var isAvailable: Bool { self.pluginProvider.isAvailable }
    var isReady: Bool { self.pluginProvider.isReady }

    func prepare(progressHandler: ((Double) -> Void)?) async throws {
        try await self.pluginProvider.prepare(progressHandler: progressHandler)
    }

    func transcribe(_ samples: [Float]) async throws -> ASRTranscriptionResult {
        let result = try await self.pluginProvider.transcribe(samples)
        return ASRTranscriptionResult(text: result.text, confidence: result.confidence)
    }

    func modelsExistOnDisk() -> Bool {
        self.pluginProvider.modelsExistOnDisk()
    }

    func refreshModelsExistOnDiskAsync() async -> Bool {
        await self.pluginProvider.refreshModelsExistOnDiskAsync()
    }

    func clearCache() async throws {
        try await self.pluginProvider.clearCache()
    }
}
