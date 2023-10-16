//
//  AuidoConverter.swift
//  JQYamnet-JQYamnet
//
//  Created by David on 2023/10/12.
//

import Foundation
import AVFoundation

extension AudioBuffer {
    func array() -> [Int16] {
        return Array(UnsafeBufferPointer(self))
    }
}

extension AVAudioPCMBuffer {
    func array() -> [Int16] {
        return self.audioBufferList.pointee.mBuffers.array()
    }

    func floatArray() -> [Float] {
        self.array().map { Float32($0) / Float32(Int16.max) }
    }
}

enum AuidoConverter {

    /// 音频数据重采样
    /// - Parameters:
    ///   - inputBuffer: 输入的buffer
    ///   - targetSampleRate: 目标采样率
    /// - Returns: 输出的buffer
    static func resampleAudioBuffer(inputBuffer: AVAudioPCMBuffer, targetSampleRate: Double) -> AVAudioPCMBuffer? {
        if inputBuffer.format.sampleRate == targetSampleRate, inputBuffer.format.commonFormat == .pcmFormatInt16  {
            // 采样率相同，无需重采样，直接返回原始音频数据
            return inputBuffer.copy() as? AVAudioPCMBuffer
        }
        
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false)!
        
        // 计算目标音频数据的帧数
        let inputFrameCount = AVAudioFrameCount(inputBuffer.frameLength)
        let outputFrameCount = AVAudioFrameCount((targetSampleRate / inputBuffer.format.sampleRate) * Double(inputFrameCount))

        // 创建具有足够容量的新输出音频缓冲区
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: max(outputFrameCount, inputFrameCount))!
        let converter = AVAudioConverter(from: inputBuffer.format, to: outputFormat)!
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return inputBuffer
        }
        var error: NSError?
        let _ = converter.convert(
            to: outputBuffer,
            error: &error,
            withInputFrom: inputBlock)
        if error == nil {
            return outputBuffer
        } else {
            return nil
        }
    }
}
