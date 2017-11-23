//
//  ViewController.swift
//  STT and TTS
//
//  Created by Emir haktan Ozturk on 22.11.2017.
//  Copyright © 2017 emirhaktan. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

@available(iOS 10.0, *)
class ViewController: UIViewController,SFSpeechRecognizerDelegate,UITextViewDelegate, UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource{

    @IBOutlet var textView: UITextView!
    
    @IBOutlet var languageTextField: UITextField!
    @IBOutlet weak var sttButton: UIButton!
    
    var languageOption = ["...","en-US","pl-PL","tr-TR","de-DE"]
    
    private var speechRecognizer :SFSpeechRecognizer? = {
        let iosVersion = NSString(string: UIDevice.current.systemVersion).doubleValue
        return (iosVersion >= 10 ? SFSpeechRecognizer()! : nil)
    }()
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupPickerTextField()
        prepareSpeechRecognizer()
    }
    
    // Preperation of the speech recognizer
    func prepareSpeechRecognizer(){
        
        sttButton.isEnabled = false //2
        speechRecognizer?.delegate = self  //3
        
        if #available(iOS 10, *) {
            SFSpeechRecognizer.requestAuthorization { (authStatus) in // 4
                
                var isButtonEnabled = false
                
                switch authStatus { // 5
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
                    self.sttButton.isEnabled = isButtonEnabled
                }
            }
        }
    }
    
    // start recording and get the best transcription
    func startRecording() {
        
        // check if recognition task working. If so, cancel the task and the reognition.
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        //Create an AVAudioSession to prepare for the audio recording. Here we set the category of the session as recording, the mode as measurement, and activate it. Setting these properties may throw an exception, so it has to be in a catch clause.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        //Instantiate the recognitionRequest. Here we create the SFSpeechAudioBufferRecognitionRequest object. Later, we use it to pass our audio data to Apple’s servers.
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        //Give audioEngine(the device) an audio input for recording
         let inputNode = audioEngine.inputNode
        
        //Check if the recognitionRequest object is instantiated and is not nil.
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        //Tell recognitionRequest to report partial results of speech recognition as the user speaks.
        recognitionRequest.shouldReportPartialResults = true
        
        //Start the recognition by calling the recognitionTask method of our speechRecognizer. This function has a completion handler. This completion handler will be called every time the recognition engine has received input, has refined its current recognition, or has been canceled or stopped, and will return a final transcript.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            //Define a boolean to determine if the recognition is final.
            var isFinal = false
            
            // If the result isn’t nil, set the textView.text property as our result‘s best transcription. Then if the result is the final result, set isFinal to true.
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            //If there is no error or the result is final, stop the audioEngine (audio input) and stop the recognitionRequest and recognitionTask. At the same time, we enable the Start Recording button(sttButton).
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.sttButton.isEnabled = true
            }
        })
        
        //Add an audio input to the recognitionRequest. Note that it is ok to add the audio input after starting the recognitionTask. The Speech Framework will start recognizing as soon as an audio input has been added.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        //Prepare and start the audioEngine.
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    public  func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            sttButton.isEnabled = true
        } else {
            sttButton.isEnabled = false
        }
    }
    
    @IBAction func sttAction(_ sender: Any) {
        if self.audioEngine.isRunning {
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.sttButton.isEnabled = false
            self.sttButton.setImage(UIImage(named:"microphone_icon"), for: .normal)
        } else {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: self.languageTextField.text!))
            self.startRecording()
            self.sttButton.setImage(UIImage(named:"microphoneStop_icon"), for: .normal)
        }
    }
    
    @IBAction func ttsAction(_ sender: Any) {
        let utterance = AVSpeechUtterance(string: textView.text) // 1
        utterance.voice = AVSpeechSynthesisVoice(language: languageTextField.text) // 2
        utterance.rate = 0.5 // 3
        
        let synthesizer = AVSpeechSynthesizer() // 4
        synthesizer.speak(utterance) // 5
    }
    
                                    /*      UI METHODS      */
    // set up textField
    func setupPickerTextField(){
        let borderColor = UIColor.rgb(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0)
        self.languageTextField.layer.borderColor = borderColor.cgColor
        self.languageTextField.layer.borderWidth = 1.0
        let pickerView = UIPickerView()
        pickerView.backgroundColor = UIColor.white
        pickerView.delegate = self
        languageTextField.inputView = pickerView
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.blue
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPicker))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        languageTextField.inputView = pickerView
        languageTextField.inputAccessoryView = toolBar
    }
    // picker selector methods
    @objc func donePicker(){
        languageTextField.resignFirstResponder()
    }
    @objc func cancelPicker(){
        languageTextField.text = ""
        languageTextField.resignFirstResponder()
    }
    
    func setupTextView(){
        let borderColor = UIColor.rgb(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0)
        textView.delegate = self
        textView.layer.borderColor = borderColor.cgColor
        textView.layer.borderWidth = 1.0
        textView.textColor = UIColor.lightGray
        textView.returnKeyType = .done
        textView.text = "Text to enter or text to be spoken..."
    }
    
    // textView delegate methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView.textColor == UIColor.lightGray{
            self.textView.text = ""
            self.textView.textColor = UIColor.black
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textView.resignFirstResponder()
        return true
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == ""{
            setupTextView()
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            self.textView.resignFirstResponder()
            return false
        }
        return true
    }
    // picker delegate methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languageOption.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languageOption[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        languageTextField.text = languageOption[row]
    }
}

extension UIColor {
    static func rgb(red:CGFloat, green: CGFloat, blue:CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
}

