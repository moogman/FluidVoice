import Foundation
import FluidSpeechAnalyzerPluginInterface

extension DebugLogger: SpeechAnalyzerPluginLogger {}

final class SpeechAnalyzerPluginLoader {
    static let shared = SpeechAnalyzerPluginLoader()

    private var didAttemptLoad: Bool = false
    private var cachedProvider: (any SpeechAnalyzerProvider)?

    private init() {}

    func makeProvider() -> (any SpeechAnalyzerProvider)? {
        if let cachedProvider = self.cachedProvider {
            return cachedProvider
        }

        if self.didAttemptLoad {
            return nil
        }
        self.didAttemptLoad = true

        if #available(macOS 26.0, *) {
            guard let frameworksURL = Bundle.main.privateFrameworksURL else {
                DebugLogger.shared.debug("SpeechAnalyzer plugin load skipped: no privateFrameworksURL", source: "SpeechAnalyzerPluginLoader")
                return nil
            }

            let pluginURL = frameworksURL.appendingPathComponent("FluidSpeechAnalyzerPlugin.framework")
            guard let pluginBundle = Bundle(url: pluginURL) else {
                DebugLogger.shared.debug("SpeechAnalyzer plugin not found at: \(pluginURL.path)", source: "SpeechAnalyzerPluginLoader")
                return nil
            }

            guard pluginBundle.load() else {
                DebugLogger.shared.warning("SpeechAnalyzer plugin failed to load: \(pluginURL.path)", source: "SpeechAnalyzerPluginLoader")
                return nil
            }

            guard let entryType = NSClassFromString("FluidSpeechAnalyzerPlugin.FluidSpeechAnalyzerPluginEntryPoint") as? (any SpeechAnalyzerPluginEntryPoint.Type) else {
                DebugLogger.shared.warning("SpeechAnalyzer plugin loaded but entry point not found", source: "SpeechAnalyzerPluginLoader")
                return nil
            }

            let provider = entryType.makeProvider(logSink: DebugLogger.shared)
            self.cachedProvider = provider
            return provider
        }

        return nil
    }
}
