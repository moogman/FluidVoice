import FluidSpeechAnalyzerPluginInterface
import Foundation

public final class FluidSpeechAnalyzerPluginEntryPoint: SpeechAnalyzerPluginEntryPoint {
    public static func makeProvider(logSink: (any SpeechAnalyzerPluginLogger)?) -> (any SpeechAnalyzerProvider)? {
        #if ENABLE_SPEECH_ANALYZER
        if #available(macOS 26.0, *) {
            return AppleSpeechAnalyzerProvider(logSink: logSink)
        }
        return nil
        #else
        return nil
        #endif
    }
}
