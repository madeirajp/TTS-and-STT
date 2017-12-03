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
class ViewController: UIViewController,AVSpeechSynthesizerDelegate,SFSpeechRecognizerDelegate,UITextViewDelegate, UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource,SettingsViewControllerDelegate{

    

    @IBOutlet var textView: UITextView!
    
    @IBOutlet var languageTextField: UITextField!
    @IBOutlet weak var sttButton: UIButton!
    @IBOutlet weak var ttsButton: UIButton!
    
    var arrLanguages: [Dictionary<String, String?>] = []
    
    private var speechRecognizer :SFSpeechRecognizer? = {
        let iosVersion = NSString(string: UIDevice.current.systemVersion).doubleValue
        return (iosVersion >= 10 ? SFSpeechRecognizer()! : nil)
    }()
    
    var rate: Float!
    
    var pitch: Float!
    
    var volume: Float!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var utterance = AVSpeechUtterance()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareLanguages()
        self.speechSynthesizer.delegate = self
        if !loadSettings(){
            registerDefaultTTSSettings()
        }
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
                    self.createAlert(title: "Access Denied by User", message: "Speech Recognition has been denied. Please allow speech recognition from the Settings", actionTitle: "Close")//////
                    print("User denied access to speech recognition")
                    
                case .restricted:
                    isButtonEnabled = false
                    self.createAlert(title: "Error", message: "Speech recognition restricted on this device", actionTitle: "Close")////////
                    print("Speech recognition restricted on this device")
                    
                case .notDetermined:
                    isButtonEnabled = false
                    self.createAlert(title: "No Authorization", message: "Speech recognition not yet authorized", actionTitle: "Close")
                    print("Speech recognition not yet authorized")
                }
                
                OperationQueue.main.addOperation() {
                    self.sttButton.isEnabled = isButtonEnabled
                }
            }
        }
    }
    
    func createAlert(title:String, message:String, actionTitle:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
            self.createAlert(title: "Error!", message: "audioSession properties weren't set because of an error.", actionTitle: "Close")////////////
            print("audioSession properties weren't set because of an error. ")
        }
        
        //Instantiate the recognitionRequest. Here we create the SFSpeechAudioBufferRecognitionRequest object. Later, we use it to pass our audio data to Apple’s servers.
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        //Give audioEngine(the device) an audio input for recording
         let inputNode = audioEngine.inputNode
        
        //Check if the recognitionRequest object is instantiated and is not nil.
        guard let recognitionRequest = recognitionRequest else {
            self.createAlert(title: "Error!", message: "Unable to create an SFSpeechAudioBufferRecognitionRequest object", actionTitle: "Close")/////
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
            self.createAlert(title: "Error!", message: "audioEngine couldn't start because of an error", actionTitle: "Close")///
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
    
    // Preparing the supported languages
    func prepareLanguages(){
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            
            let voiceLanguageCode = (voice as AVSpeechSynthesisVoice).language  // getting language code from avspeechsynthesisvoice
            
            let languageName = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: voiceLanguageCode)
            let dictionary = ["languageName": languageName, "languageCode": voiceLanguageCode]
            
            arrLanguages.append(dictionary)
        }
    }
    
    func registerDefaultTTSSettings(){ //// save default settings
        rate = AVSpeechUtteranceDefaultSpeechRate
        pitch = 1.0
        volume = 1.0
        let defaultSpeechSettings: Dictionary<NSObject, AnyObject> = ["rate" as NSObject: rate as AnyObject, "pitch" as NSObject: pitch as AnyObject, "volume" as NSObject: volume as NSObject]
        
        UserDefaults.standard.register(defaults: defaultSpeechSettings as! [String : Any])
    }
    
    func loadSettings() -> Bool {// Load user defaults
        let userDefaults = UserDefaults.standard as UserDefaults
        
        if let theRate: Float = userDefaults.value(forKey: "rate") as? Float {
            rate = theRate
            pitch = userDefaults.value(forKey: "pitch") as! Float
            volume = userDefaults.value(forKey: "volume") as! Float
            
            return true
        }
        
        return false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {// set button image back to speak icon
        self.ttsButton.setImage(UIImage(named:"speaker_icon"), for: .normal)
    }
    
    @IBAction func ttsAction(_ sender: Any) {////
        
        if speechSynthesizer.isSpeaking{
            speechSynthesizer.stopSpeaking(at: .immediate)
            self.ttsButton.setImage(UIImage(named:"speaker_icon"), for: .normal)
        }
        else {
            self.speakTTS()
            self.ttsButton.setImage(UIImage(named:"speakerStop_icon"), for: .normal)
        }
        
    }
    
    func speakTTS(){//
        self.utterance = AVSpeechUtterance(string: textView.text) // 1
        self.utterance.voice = AVSpeechSynthesisVoice(language: languageTextField.text) // 2
        
        self.utterance.rate = rate //0.5 // 3
        self.utterance.pitchMultiplier = pitch//0.25
        self.utterance.volume = volume // 0.75
        
        //        let synthesizer = AVSpeechSynthesizer() // 4
        speechSynthesizer.speak(utterance) // 5
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {//
        if segue.identifier == "idSegueSettings" {
            let settingsViewController = segue.destination as! SettingsViewController
            settingsViewController.delegate = self
        }
    }
    
    func didSaveSettings() {//
        let settings = UserDefaults.standard as UserDefaults!
        
        rate = settings?.value(forKey: "rate") as! Float
        pitch = settings?.value(forKey: "pitch") as! Float
        volume = settings?.value(forKey: "volume") as! Float
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
//        return languageOption.count
        return arrLanguages.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return languageOption[row]
        let voiceLanguagesDictionary = arrLanguages[row] as Dictionary<String, String?>
        
        return voiceLanguagesDictionary["languageName"]!
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        languageTextField.text = languageOption[row]
        let voiceLanguagesDictionary = arrLanguages[row] as Dictionary<String, String?>
        languageTextField.text = voiceLanguagesDictionary["languageCode"]!
    }
}

extension UIColor {
    static func rgb(red:CGFloat, green: CGFloat, blue:CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
}

