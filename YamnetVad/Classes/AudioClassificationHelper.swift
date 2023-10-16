//
//  File.swift
//  JQYamnet
//
//  Created by David on 2023/10/13.
//

import TensorFlowLiteTaskAudio
import AVFoundation

protocol AudioClassificationHelperDelegate: AnyObject {
    func audioClassification(_ audioClassifier: AudioClassificationHelper, didSucceed result: Result)
    func audioClassification(_ audioClassifier: AudioClassificationHelper, didFail error: Error)
}

/// 识别结果
struct Result {
    /// 返回的所有结果(根据设置的最大返回数量进行返回)
    let categories: [ClassificationCategory]
}

class AudioClassificationHelper {

    // MARK: Public properties
    /// 识别代理
    weak var delegate: AudioClassificationHelperDelegate?

    // MARK: Private properties

    /// 识别器
    private let classifier: AudioClassifier

    /// 输入组件
    private let inputAudioTensor: AudioTensor

    /// 缓存的数据（用于将数据做成数据流）
    private var audioBuffer: [Float] = []

    /// 需要捕获的秒数
    private let secondsToCapture: Float = 1

    /// 采样率
    var sampleRate: UInt { inputAudioTensor.audioFormat.sampleRate }

    /// A failable initializer for `AudioClassificationHelper`.
    init?(modelFileName: String = "yamnet",
          threadCount: Int = 1,
          scoreThreshold: Float = 0.0,
          maxResults: Int = 1,
          delegate: AudioClassificationHelperDelegate? = nil) {

        // Construct the path to the model file.
        guard let bundlePath = Bundle.main.path(forResource: "YamnetVad", ofType: "bundle"),
              let bundle = Bundle(path: bundlePath),
              let modelPath = bundle.path(forResource: modelFileName, ofType: "tflite") else {
            print("Failed to load the model file \(modelFileName).tflite.")
            return nil
        }

        self.delegate = delegate

        // Specify the options for the classifier.
        let classifierOptions = AudioClassifierOptions(modelPath: modelPath)
        classifierOptions.baseOptions.computeSettings.cpuSettings.numThreads = threadCount
        classifierOptions.classificationOptions.maxResults = maxResults
        classifierOptions.classificationOptions.scoreThreshold = scoreThreshold

        do {
            // Create the classifier.
            classifier = try AudioClassifier.classifier(options: classifierOptions)
            
            // Create an `AudioRecord` instance to record input audio that satisfies
            // the model's requirements.
            inputAudioTensor = classifier.createInputAudioTensor()
        } catch {
            print("Failed to create the classifier with error: \(error.localizedDescription)")
            return nil
        }
    }

    func start(inputBuffer: [Float]) {
        self.audioBuffer.append(contentsOf: inputBuffer)
        // 如果音频数据超出缓冲区容量，移除旧数据
        let sampleCountToCapture = Int(Float(self.sampleRate) * self.secondsToCapture)
        if self.audioBuffer.count > sampleCountToCapture {
            let excessCount = self.audioBuffer.count - sampleCountToCapture
            self.audioBuffer.removeFirst(excessCount)
        }
        self.getResult(inputBuffer: self.audioBuffer)
    }

    func clearBuffer() {
        self.audioBuffer.removeAll()
        self.inputAudioTensor.buffer.clear()
    }

    private func getResult(inputBuffer: [Float]) {
        do {
            var mutableInput = Array(self.audioBuffer)
            try mutableInput.withUnsafeMutableBufferPointer { buffer in
                let floatBuffer = TFLFloatBuffer(data: buffer.baseAddress!, size: UInt(buffer.count))
                try self.inputAudioTensor.load(buffer: floatBuffer, offset: 0, size: UInt(buffer.count))
                let results = try self.classifier.classify(audioTensor: self.inputAudioTensor)
                let result = Result(categories: results.classifications[0].categories)
                self.delegate?.audioClassification(self, didSucceed: result)
            }
        } catch let error {
            self.delegate?.audioClassification(self, didFail: error)
        }
    }
}
