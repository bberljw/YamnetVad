//
//  File.swift
//  JQYamnet-JQYamnet
//
//  Created by David on 2023/10/12.
//

import Foundation
import AVFoundation

/// 识别结果
public struct YamnetResult {
    // 分数
    public var score: Float32 = 0.0
    // 名称
    public var label: String?
    // 静音
    public var isSlience: Bool { label?.isEmpty ?? true }
    // 说话
    public var isSpeech: Bool { label == "Speech" }
    // 音乐
    public var isMusic: Bool { label == "Music" }
}

/// 音频识别代理
public protocol YamnetRecognizerDelegate: AnyObject {
    /// 音频识别器返回识别结果
    /// - Parameters:
    ///   - recognizer: 识别器
    ///   - didRecognizeResult: 识别结果数组（根据设置的默认返回数量，返回顺序的识别结果）
    func soundRecognizer(_ recognizer: YamnetRecognizer, didRecognizeResult results: [YamnetResult])
}

/// 音频识别
public class YamnetRecognizer {

    // MARK: - Constants
    /// 默认返回2条结果
    private var classifier: AudioClassificationHelper?
    /// 缓存数据的数组
    private var cacheBuffers: [Float] = []
    
    // MARK: - Variables
    public weak var delegate: YamnetRecognizerDelegate?

    // 返回结果的数量，按照分数由高到低返回，默认返回一个结果
    public var resultCount: UInt = 1 {
        didSet {
            if resultCount > 521 { resultCount = 521 }
        }
    }

    // 识别线程
    private let processQueue = DispatchQueue(label: "com.yamnet.queue")

    // 默认缓存的采样点个数，超过此值，才会进行输入（1920大概为60ms音频数据）
    public var bufferCacheCount: Int = 1920

    // MARK: - Public Methods
    public init(delegate: YamnetRecognizerDelegate? = nil) {
        self.delegate = delegate
        self.classifier = AudioClassificationHelper(maxResults: 2, delegate: self)
    }

    /// 输入音频
    /// - Parameter buffer: 输入的数据流
    public func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        self.processQueue.async {
            guard let classifier = self.classifier,
                  let convertedBuffer = AuidoConverter.resampleAudioBuffer(inputBuffer: buffer,
                                                                           targetSampleRate: Double(classifier.sampleRate)) else { return }
            let samples = convertedBuffer.floatArray()
            // 单次大于缓存，可以直接输入，不需要控制频率
            if self.cacheBuffers.count == 0, samples.count >= self.bufferCacheCount {
                classifier.start(inputBuffer: samples)
                return
            }
            self.cacheBuffers.append(contentsOf: samples)
            // 大于缓存大小才进行输入,控制识别频率
            if self.cacheBuffers.count >= self.bufferCacheCount {
                // 先把数组缓拷贝一份
                let array = Array(self.cacheBuffers)
                classifier.start(inputBuffer: array)
                self.cacheBuffers.removeFirst(self.bufferCacheCount)
            }
        }
    }

    /// 清理缓存
    public func clearBuffer() {
        self.processQueue.async {
            self.classifier?.clearBuffer()
            self.cacheBuffers.removeAll()
        }
    }
}

extension YamnetRecognizer: AudioClassificationHelperDelegate {

    func audioClassification(_ audioClassifier: AudioClassificationHelper, didFail error: Error) {
        print("Failed to recognize buffer \(error.localizedDescription)")
    }

    func audioClassification(_ audioClassifier: AudioClassificationHelper, didSucceed result: Result) {
        var results = [YamnetResult]()
        for category in result.categories {
            let result = YamnetResult(score: category.score, label: category.label)
            results.append(result)
        }
        DispatchQueue.main.async {
            self.delegate?.soundRecognizer(self, didRecognizeResult: results)
        }
    }
}
