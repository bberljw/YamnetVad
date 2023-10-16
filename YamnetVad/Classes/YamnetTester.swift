//
//  YamnetTester.swift
//  JQYamnet
//
//  Created by David on 2023/10/16.
//

import Foundation
import AVFoundation

/// 用于进行测试
/// 代码 YamnetTester.shared.startRecorder()
public class YamnetTester {
    
    public static let shared = YamnetTester()
    
    private var audioEngine: AVAudioEngine? = nil
    private var recognizer: YamnetRecognizer?

    init() {
        initRecorder()
        recognizer = YamnetRecognizer(delegate: self)
    }

    private func initRecorder() {
        print("init recorder")
        audioEngine = AVAudioEngine()
        let inputNode = self.audioEngine?.inputNode
        let bus = 0
        let inputFormat = inputNode?.outputFormat(forBus: bus)
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000, channels: 1,
            interleaved: false)!
        let converter = AVAudioConverter(from: inputFormat!, to: outputFormat)!
        inputNode!.installTap(
            onBus: bus,
            bufferSize: 10,
            format: inputFormat
        ) {
            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            var newBufferAvailable = true
            
            let inputCallback: AVAudioConverterInputBlock = {
                inNumPackets, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            
            let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity:
                    AVAudioFrameCount(outputFormat.sampleRate)
                * buffer.frameLength
                / AVAudioFrameCount(buffer.format.sampleRate))!
            
            var error: NSError?
            let _ = converter.convert(
                to: convertedBuffer,
                error: &error, withInputFrom: inputCallback)
            self.recognizer?.appendBuffer(convertedBuffer)
        }
    }
    
    public func startRecorder() {
        do {
            try self.audioEngine?.start()
        } catch let error as NSError {
            print("Got an error starting audioEngine: \(error.domain), \(error)")
        }
        print("started")
    }

    public func stopRecorder() {
        audioEngine?.stop()
        print("stopped")
    }
}

extension YamnetTester: YamnetRecognizerDelegate {
    public func soundRecognizer(_ recognizer: YamnetRecognizer, didRecognizeResult results: [YamnetResult]) {
        results.forEach { result in
            NSLog("识别结果 name: \(result.label ?? ""), score: \(result.score)")
        }
    }
}
