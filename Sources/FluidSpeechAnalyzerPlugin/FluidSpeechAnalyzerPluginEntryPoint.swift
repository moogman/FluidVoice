import FluidSpeechAnalyzerPluginInterface
import Foundation

public final class FluidSpeechAnalyzerPluginEntryPoint: SpeechAnalyzerPluginEntryPoint {
    public static func makeProvider(logSink: (any SpeechAnalyzerPluginLogger)?) -> (any SpeechAnalyzerProvider)? {
        #if ENABLE_SPEECH_ANALYZER
        return AppleSpeechAnalyzerProvider(logSink: logSink)
        #else
        return nil
        #endif
    }
}
