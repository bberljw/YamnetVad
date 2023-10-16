//
//  ViewController.swift
//  YamnetVad
//
//  Created by 刘金伟 on 10/16/2023.
//  Copyright (c) 2023 刘金伟. All rights reserved.
//

import UIKit
import AVFoundation
import YamnetVad

class ViewController: UIViewController, YamnetRecognizerDelegate {

    lazy var recognizer: YamnetRecognizer = YamnetRecognizer(delegate: self)

    var audioEngine: AVAudioEngine? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initRecorder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func initRecorder() {
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
            self.recognizer.appendBuffer(convertedBuffer)
        }
    }
    
    @IBAction func startRecord(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            startRecorder()
        } else {
            stopRecorder()
        }
    }
    
    func startRecorder() {
        do {
            try self.audioEngine?.start()
        } catch let error as NSError {
            print("Got an error starting audioEngine: \(error.domain), \(error)")
        }
        print("started")
    }

    func stopRecorder() {
        audioEngine?.stop()
        print("stopped")
    }
    
    func soundRecognizer(_ recognizer: YamnetRecognizer, didRecognizeResult results: [YamnetResult]) {
        results.forEach { result in
            NSLog("识别结果 name: \(result.label ?? ""), score: \(result.score)")
        }
    }
}
