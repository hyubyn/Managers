//
//  RecorderView.swift
//  SpeechToText
//
//  Created by NguyenVuHuy on 7/27/17.
//  Copyright © 2017 Hyubyn. All rights reserved.
//

import UIKit
import SnapKit
import Speech

protocol RecorderViewDelegate {
    func didRecordTask(task: String)
    func didCancelRecord()
}

class RecorderView: UIView {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.clipsToBounds = false
        label.text = Constants.InfoLabelNormalText
        label.textColor = UIColor.white
        label.layer.borderColor = Constants.ComponentsBorderColor
        return label
    }()
    
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.green.withAlphaComponent(0.8).cgColor
        textView.delegate = self
        return textView
    }()
    
    lazy var recordButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = false
        button.backgroundColor = Constants.ThemeColor
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.setTitle(Constants.RecordButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = Constants.ThemeColor
        button.setTitleColor(UIColor.white, for: .normal)
        button.clipsToBounds = false
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        view.backgroundColor = Constants.ThemeColor
        return view
    }()
    
    var delegate: RecorderViewDelegate?
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: Constants.ENLocaleIdentifier))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        super.init(frame: CGRect.zero)
        setupView()
        setupRecorder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // set locale for Speech
    func setLocale(isUS: Bool) {
        if isUS {
            speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: Constants.ENLocaleIdentifier))
        } else {
            speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: Constants.VNLocaleIdentifier))
        }
    }
    
    // setup view components
    func setupView() {
        
        backgroundColor = UIColor.clear
        
        // mask view make background color when superView is clear
        let maskView = UIView()
        maskView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        addSubview(maskView)
        maskView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(0)
        }
        
        addSubview(containerView)
        
        // The containerView display popup where user interact in
        containerView.snp.makeConstraints { (maker) in
            maker.center.equalTo(snp.center)
            maker.leading.trailing.equalTo(0).inset(20)
            maker.height.equalTo(self).dividedBy(2)
        }
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(textView)
        containerView.addSubview(recordButton)
        containerView.addSubview(cancelButton)
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(0)
            maker.leading.trailing.equalTo(0)
            maker.height.equalTo(50)
        }
        
        recordButton.snp.makeConstraints { (maker) in
            maker.leading.bottom.equalTo(0)
            maker.width.equalTo(containerView).dividedBy(2)
            maker.height.equalTo(50)
        }
        
        cancelButton.snp.makeConstraints { (maker) in
            maker.trailing.bottom.equalTo(0)
            maker.width.equalTo(containerView).dividedBy(2)
            maker.height.equalTo(recordButton)
        }
        
        textView.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom)
            maker.leading.trailing.equalTo(0).inset(20)
            maker.bottom.equalTo(recordButton.snp.top)
        }
    }
    
    
    // func setup recorder to record user voice from speech to text
    func setupRecorder() {
        guard let recognizer = speechRecognizer else { return }
        
        recognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.recordButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    // start record, change title label text
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        titleLabel.text = Constants.InfoLabelRecordingText
    }
    
    // record button tapped
    func recordButtonTapped() {
        if audioEngine.isRunning {
            titleLabel.text = Constants.InfoLabelNormalText
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle(Constants.RecordButtonTitle, for: .normal)
            if let text = textView.text, textView.text.characters.count > 0 {
                textView.text = ""
                delegate?.didRecordTask(task: text)
            }
        } else {
            startRecording()
            recordButton.setTitle(Constants.SaveButtonTitle, for: .normal)
        }
        
    }
    
    // cancel button Tapped
    func cancelButtonTapped() {
        if audioEngine.isRunning {
            textView.text = ""
            titleLabel.text = Constants.InfoLabelNormalText
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.setTitle(Constants.RecordButtonTitle, for: .normal)
        }
        delegate?.didCancelRecord()
    }
}

extension RecorderView: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        recordButton.isEnabled = available
    }
}

extension RecorderView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        startRecording()
        recordButton.setTitle(Constants.SaveButtonTitle, for: .normal)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

class Constants {
    static let ComponentsBorderColor = UIColor.black.withAlphaComponent(0.8).cgColor
    static let ThemeColor = UIColor.init(colorLiteralRed: 68/255, green: 216/255, blue: 1, alpha: 0.8)
    static let RecordViewTitle = "Create New Record"
    static let InfoLabelNormalText = "Press Start to record new task"
    static let InfoLabelRecordingText = "Recording..."
    static let RecordButtonTitle = "Start Record"
    static let SaveButtonTitle = "Stop and Save"
    static let VNLocaleIdentifier = "vi-VN"
    static let ENLocaleIdentifier = "en-US"
}
