//
//  RecordingScreenViewController.swift
//  Khoa IELTS
//
//  Created by ColWorx on 03/01/2019.
//  Copyright © 2019 ast. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftSiriWaveformView
import Speech
import PKHUD
import AudioKit

class RecordingScreenViewController: UIViewController, AVAudioRecorderDelegate, AVSpeechSynthesizerDelegate {
    
    var part2 = Bool()
    var part2Initialize = Bool()
    var part = Bool()
    //18 - 01 - 2019
//    var textToSpeech = [[String: AnyObject]]()
    var categoryname = String()

    var indexedTopicContent = String()
    var topicNames = [String]()
    var topicContents = [String]()
    var topicFrequencies = [[Float]]()
    var seperateStringByWordsArray = [String]()
    var seperateStringByWordsCounter = 0
    var vocabsInStringsCounter = 0
    
    var repetitionOfWordsCounter = [Int]()
    var totalWordsInSentenceCounter = [Int]()
    var vocabsInSentenceCounter = [Int]()
    var index = 0
    var numberOfSentences = 0
    var punctuatedStrings = [String]()
    var topicSeparatedBySentences = [[String]]()
    
    
    var hypotheticalSituation = 0
    var modalVerbs = 0
    
    //21 - 01 - 2019
    
    var collocationsInSentencesCounter = 0
    var collocationsInSentences = [[String:String]]()
    
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    
    
    //Old Code
    let mic = AKMicrophone()
    var tracker : AKFrequencyTracker!
    var silence : AKBooster!
    var currentFrequency = [Float]()
    var noteFrequencies = [[Float]]()
    var insertFirstItem = false
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    let speechSynthesizer = AVSpeechSynthesizer()
    
    
    var startRecordingTimer = Timer()
    var callTextToSpeech  = Timer()
    var updateSoundWaves = Timer()
    var updateUITimer = Timer()
    
    
    var data = Dictionary<String,AnyObject>()
    var urls = [URL]()
    var topicCount = Int()
    var change:CGFloat = 0.01
    var recordingStart = 0
    var recordingTimer = 0
    var globalIndex = 0
    var tableViewReloader = 1
    var toRootViewController :Bool = false
    
    var textToSpeech = [[String: AnyObject]]()
    
    var textToSpeechCounter = 0
    
    var recordSampleResult : Bool = false
    var resumeRecording = false
    @IBOutlet weak var mainHeadingLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var audioWave: SwiftSiriWaveformView!
    @IBOutlet weak var countdownTimer: UILabel!
    @IBOutlet weak var subtitleSwitch: UISwitch!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var exitBtn: UIButton!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var nextQuesBtn: RoundedButtons!
    @IBOutlet weak var timerImageView: UIView!
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var popUoContectView: UIView!
    @IBOutlet weak var subtitleView: UIView!
    @IBOutlet weak var practicePaused: UILabel!
    @IBOutlet weak var soundWaveView: UIView!
    
    @IBOutlet weak var part2View: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 20
        speechSynthesizer.delegate = self
//        speechRecognizer?.delegate = self
        
        exitBtn.isHidden = true
        timerImageView.isHidden = true
        subtitleSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        mainHeadingLabel.text = data["topicTitle"] as? String
        topicCount = (data["topics"] as! Array<String>).count
        
        self.popUoContectView.layer.cornerRadius = 10.0;
        self.popUpView.backgroundColor = UIColor(red: 0.0/255, green: 0.0/255, blue: 0.0/255, alpha: 0.60)
        
        
        audioWave.amplitude = 0.1
        audioWave.numberOfWaves = 10
        audioWave.waveColor = UIColor(red: 62.0/255, green: 255.0/255, blue: 255.0/255, alpha: 1)
        
        tracker = AKFrequencyTracker.init(mic)
        let silence = AKBooster(tracker, gain: 0)
        AudioKit.output = silence
        
        if data["part"] as! String == "Part - 2" {
            mainHeadingLabel.isHidden = true
            tableView.isHidden = true
            part2View.isHidden = false
            part2 = true
            part2Initialize = true
            part = true

        } else {
            recordingTimer = 0
            mainHeadingLabel.isHidden = false
            tableView.isHidden = false
            part2View.isHidden = true
            part2Initialize = true
            part = false
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        if toRootViewController {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    @IBAction func backBtnTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func startRecordingTapped(_ sender: Any) {
        if(globalIndex == topicCount) {
            cancelTimer()
            finishRecording(false)
            nextQuesBtn.alpha = 0.5
            nextQuesBtn.isEnabled = false
            popUpView.isHidden = false
            return
        }
        if recordingStart == 0 {
            recordingSession = AVAudioSession.sharedInstance()
            do {
                recordingSession.requestRecordPermission() { [unowned self] allowed in
                    DispatchQueue.main.async {
                        if allowed {
                            let image = UIImage(named: "stop_btn")
                            self.recordBtn.setImage(image, for: .normal)
                            self.recordingStart = 1
                            self.readSentence()
                        } else {
                            let alert = UIAlertController(title: "Alert", message: "You need allow microphone access from Settings", preferredStyle: .alert)
                            let alertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                            alert.addAction(alertAction)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            return
        } else {
            self.countdownTimer.text = "00:00:00"
            recordingTimer = 0
            addFrequencies()
            recordingStart = 0
            popUpView.isHidden = false
            audioRecorder.pause()
            cancelTimer()
        }
    }
    @IBAction func exitBtnTapped(_ sender: Any) {
        
        resumeRecording = true
        
        startRecordingTimer.invalidate()
        audioRecorder.pause()
        popUpView.isHidden = false
    }
    @IBAction func subtitleOnOff(_ sender: Any) {
        if subtitleSwitch.isOn {
            subtitleView.isHidden = false
        } else {
            subtitleView.isHidden = true
        }
    }
    
    @IBAction func continueBtnTapped(_ sender: Any) {
        if(globalIndex == topicCount) {
            self.popUpView.isHidden = true
            return
        }
        resumeRecording = true
        self.popUpView.isHidden = true
        startRecordingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    @IBAction func startOverBtnTapped(_ sender: Any) {
        finishRecording(true)
        self.popUpView.isHidden = true
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextQuesBtnTapped(_ sender: Any) {
        self.countdownTimer.textColor = UIColor.white
        recordingTimer = 0
        popUpView.isHidden = true
        readSentence()
    }
    @available(iOS 11.0, *)
    @IBAction func endTestBtnTapped(_ sender: Any) {
        self.countdownTimer.textColor = UIColor.white
        popUpView.isHidden = true
        toRootViewController = true
        audioRecorder.stop()
        audioRecorder = nil
        cancelTimer()
        requestTranscribePermissions()
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if part2 {
            mainHeadingLabel.isHidden = false
            tableView.isHidden = false
            part2View.isHidden = true
            self.tableView.reloadData()
            timerAction()
            return
        }
        
        updateSoundWaves.invalidate()
        if globalIndex != 0 {
            audioRecorder.stop()
            audioRecorder = nil
        }
        if(globalIndex > topicCount) {
            return
        }
        loadRecordingUI()
        startRecordingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        callTextToSpeech = Timer(timeInterval: TimeInterval(recordingTimer), target: self, selector: #selector(readSentence), userInfo: nil, repeats: true)
        updateSoundWaves = Timer.scheduledTimer(timeInterval: 0.009, target: self, selector: #selector(refreshAudioView(_:)), userInfo: nil, repeats: true)
        
    }
    @objc func refreshAudioView(_:Timer) {
        if self.audioWave.amplitude <= self.audioWave.idleAmplitude || self.audioWave.amplitude > 1.0 {
            self.change *= -1.0
        }
        self.audioWave.amplitude += self.change
    }
    @objc func readSentence () {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.spokenAudio)
            try recordingSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try recordingSession.setActive(true)
        } catch {
            
        }
        
        recordBtn.isEnabled = false
        updateSoundWaves.invalidate()
        if globalIndex == (data["topics"] as! Array<String>).count {
            noteFrequencies.append(currentFrequency)
            finishRecording(true)
            return
        }
        
        if insertFirstItem {
            noteFrequencies.append(currentFrequency)
            insertFirstItem = false
        } else {
            if noteFrequencies.isEmpty {
                insertFirstItem = true
            } else {
                noteFrequencies.append(currentFrequency)
            }
        }
        if !part2Initialize {
            noteFrequencies.append(currentFrequency)
            finishRecording(true)
            return
        }
        currentFrequency = [10.0]
        if part2 {
            let speech   = AVSpeechUtterance(string: "now i'm going to give you a topic, and I'd like you to talk about it for one to two minutes. Before you talk, you'll have one minute to think about what you're going to say. You can make notes if you wish. Do you understand?")
            speech.voice = AVSpeechSynthesisVoice(language: "en-US")
            speechSynthesizer.speak(speech)
            return
        }
        
        self.tableView.reloadData()
        tableViewReloader = tableViewReloader + 1
        let sentence = (data["topics"] as! Array<String>)[globalIndex]
        let speech   = AVSpeechUtterance(string: sentence)
        speech.voice = AVSpeechSynthesisVoice(language: "en-US")
        speech.volume = 1.0
        
        speechSynthesizer.speak(speech)
    }
    
    
    
    @objc func timerAction() {
        recordingTimer = recordingTimer + 1
//        if part2 {
//            if part2Initialize {
//                part2Initialize = false
//                startRecordingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
//            }
//            if recordingTimer > 60 {
//
//                timerImageView.isHidden = false
//                let timer = recordingTimer - 60
//                if timer >= 10 {
//                    countdownTimer.text = "01:\(timer)"
//                } else {
//                    countdownTimer.text = "01:0\(timer)"
//                }
//                return
//            } else {
//                part2 = false
//                loadRecordingUI()
//                callTextToSpeech = Timer(timeInterval: TimeInterval(recordingTimer), target: self, selector: #selector(readSentence), userInfo: nil, repeats: true)
//                updateSoundWaves = Timer.scheduledTimer(timeInterval: 0.009, target: self, selector: #selector(refreshAudioView(_:)), userInfo: nil, repeats: true)
//                return
//            }
//        }
        
//        if recordingTimer < 0 {
//            if recordingTimer >= 10 {
//                countdownTimer.text = "00:\(recordingTimer)"
//            } else {
//                countdownTimer.text = "00:0\(recordingTimer)"
//            }
//        }
//        if recordingTimer == 0 {
//            countdownTimer.text = "00:00"
//            if(topicCount != globalIndex || topicCount == globalIndex) {
//                readSentence()
//                recordingTimer = 0
//                cancelTimer()
//            }
//        }
        countdownTimer.text = timeString(time: TimeInterval(recordingTimer))
    }
    
    @objc func getFrequencies() {
        print(tracker.frequency)
        let frequency = Float(tracker.frequency)
        currentFrequency.append(frequency)
    }
    
    func addFrequencies () {
        noteFrequencies.append(currentFrequency)
    }
    
    func cancelTimer () {
        startRecordingTimer.invalidate()
        updateSoundWaves.invalidate()
        updateUITimer.invalidate()
    }
    //Recording methods
    func loadRecordingUI() {
        recordingStart = 1
        exitBtn.isHidden = false
        backBtn.isHidden = true
        timerImageView.isHidden = false
        
        startRecording()
    }
    func getAudioDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    func getAudioURL() -> URL{
        let topics = data["topics"] as? Array<String>
        let title = data["title"] as? String
        let part = data["part"] as? String
        
        if part == "Part - 2" {
            
        }
        
        let path = getAudioDirectory().appendingPathComponent(title!).appendingPathComponent(part!)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path.path) {
            do {
                try fileManager.createDirectory(atPath: path.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Couldn't create document directory")
            }
        }
        NSLog("Document directory is \(path)")
        
        if globalIndex != topics?.count {
            globalIndex = globalIndex + 1
        }
        urls.append(path.appendingPathComponent(topics![globalIndex-1]+".m4a"))
        return path.appendingPathComponent(topics![globalIndex-1]+".m4a")
    }
    func startRecording(){
        recordBtn.isEnabled = true
        let audioURL = getAudioURL()
        print(audioURL.absoluteString)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            try AudioKit.start()
            if resumeRecording {
//                recordSampleResult = audioRecorder.rec
            }
            recordSampleResult = audioRecorder.record(forDuration: TimeInterval(recordingTimer))

            updateUITimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(getFrequencies), userInfo: nil, repeats: true)
            if audioRecorder.prepareToRecord() {
                if recordSampleResult == false {
                    finishRecording(false)
                }
            }
            
        } catch {
            finishRecording(false)
        }
    }
    func finishRecording(_ success: Bool) {
        if success {
            cancelTimer()
            practicePaused.text = "Practice Completed"
            popUpView.isHidden = false
            do {
                try AudioKit.stop()
                mic!.stop()
            } catch {}
            
        }
    }
        
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(true)
        }
    }
    
    
    func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 36000
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if seconds > 10 {
            self.countdownTimer.textColor = UIColor.yellow
        }
        if seconds > 20 {
            self.countdownTimer.textColor = UIColor.orange
        }
        if seconds > 30 {
            self.countdownTimer.textColor = UIColor.red
        }
        
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

//MARK: TableView functions
extension RecordingScreenViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if part2 {
            return (data["topics"] as! Array<String>).count
        } else {
            return tableViewReloader
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingScreenCell") as! RecordingScreenTableViewCell
        let topic = data["topics"] as! Array<String>
        cell.initializeCell(topic[indexPath.row])
        return cell
    }
}

//MARK: Speech Recognition Functions
extension RecordingScreenViewController : SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate {
//MARK: Permissions for Speech Recognition
    @available(iOS 11.0, *)
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    PKHUD.sharedHUD.contentView = PKHUDTextView.init(text: "Generating your result...")
                    PKHUD.sharedHUD.show()
                    self.extractFilenameAndPath()
                } else {
                    print("Transcription permission was declined.")
                    let alertController = UIAlertController(title: "Oops!", message: "You need to allow Speech Recognition to translate your answers.", preferredStyle: .alert)
                    
                    let okayBtn = UIAlertAction(title: "Ok", style: .default , handler: { _ in
                        let fileManager = FileManager.default
                        do {
                            let path = self.getAudioDirectory().appendingPathComponent(self.data["title"] as! String)
                            try fileManager.removeItem(at: path)
                        }
                        catch let error as NSError {
                            print("Ooops! Something went wrong: \(error)")
                        }
                        self.navigationController?.popViewController(animated: true)
                    })
                    alertController.addAction(okayBtn)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
//MARK: Extracting Files and Path
    @available(iOS 11.0, *)
    func extractFilenameAndPath() {
        let directoryName = urls.map { $0.lastPathComponent }
        let fileName : NSString = directoryName[textToSpeechCounter] as NSString
        let frequencies = self.noteFrequencies[textToSpeechCounter]
        textToSpeech(fileName.deletingPathExtension, urls[textToSpeechCounter], frequencies)
    }
//MARK: Converting Audio into Text
    @available(iOS 11.0, *)
    func textToSpeech(_ fileName: String, _ filePath: URL, _ frequency: [Float]) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechURLRecognitionRequest(url: filePath)
        
        request.shouldReportPartialResults = false
        
        recognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
            guard error == nil else {
                PKHUD.sharedHUD.hide()
                print("ERROR: \(error?.localizedDescription)")
                let alertController = UIAlertController(title: "Oops!", message: "There is an error, please answer the questions again.", preferredStyle: .alert)
                
                let okayBtn = UIAlertAction(title: "Ok", style: .default , handler: { _ in
                    let fileManager = FileManager.default
                    do {
                        let path = self.getAudioDirectory().appendingPathComponent(self.data["title"] as! String)
                        try fileManager.removeItem(at: path)
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                    self.navigationController?.popViewController(animated: true)
                })
                alertController.addAction(okayBtn)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            if (result?.isFinal)! {
                
                self.textToSpeechCounter = self.textToSpeechCounter + 1

                print(fileName+": "+(result?.bestTranscription.formattedString)!)
                let dictionary = ["fileName" : fileName,
                                  "fileContent" : (result?.bestTranscription.formattedString)!,
                                  "frequency" : frequency] as [String : AnyObject]
                self.textToSpeech.append(dictionary)
                if self.part {
                    self.categorizedResult()
                    return
                }
                if(self.textToSpeechCounter == self.topicCount) {
//Generating Result
                    self.categorizedResult()
                } else {
                    self.extractFilenameAndPath()
                }
            }
        })
//        if (recognizer?.isAvailable)! {
//            recognizer?.recognitionTask(with: request) { result, error in
//                guard error == nil else { print("Error: \(error!)"); return }
//                guard let result = result else { print("No result!"); return }
//                print(result.bestTranscription.formattedString)
//                self.textToSpeech[fileName] = result.bestTranscription.formattedString
//    //                self.extractFilenameAndPath()
//            }
//        } else {
//            print("Device doesn't support speech recognition")
//        }
    }
}

//func Logout(completionHandler:@escaping (Bool) -> ()) {
//    backendless?.userService.logout(
//        { user in
//            print("User logged out.")
//            completionHandler(true)
//    },
//        error: { fault in
//            print("Server reported an error: \(fault)")
//            completionHandler(false)
//    })
//}

//MARK: Generating Result..
extension RecordingScreenViewController {
    @available(iOS 11.0, *)
    func categorizedResult() {
        for index in textToSpeech {
            topicNames.append(index["fileName"] as! String)
            topicContents.append(index["fileContent"] as! String)
            topicFrequencies.append(index["frequency"] as! [Float])
        }
        self.index = 0
        punctuate()
        
    }
    
    @available(iOS 11.0, *)
    func punctuate() {
        let url = URL(string: "http://bark.phon.ioc.ee/punctuator")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postString = "text=" + topicContents[index]
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                let alertController = UIAlertController(title: "Error", message: "There is an error, please answer the question again.", preferredStyle: .alert)
                
                let okayBtn = UIAlertAction(title: "Ok", style: .default , handler: { _ in
                    let fileManager = FileManager.default
                    do {
                        let path = self.getAudioDirectory().appendingPathComponent(self.data["title"] as! String)
                        try fileManager.removeItem(at: path)
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                    self.navigationController?.popViewController(animated: true)
                })
                alertController.addAction(okayBtn)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response!)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString!)")
            self.punctuatedStrings.append(responseString!)
            self.index = self.index + 1
            
            if self.index != self.topicContents.count {
                self.punctuate()
            } else {
                DispatchQueue.main.async {
                    self.initializedResult()
                }
            }
        }
        task.resume()
    }
    @available(iOS 11.0, *)
    func initializedResult() {
        var index = 0
        for indexedContent in topicContents {
            var tempWordRepetition = 0
            indexedTopicContent = indexedContent
            var repetitionOfWords = [[String: Int]]()
            let totalWordCount = seperateStringByWords(for: indexedContent) //word counter + seperated words
            let vocabsInSentence = vocabsInStrings(for: indexedContent) // total vocabs in sentence
            for subString in seperateStringByWordsArray {
                let temp = repetitionOfWordCheck(for: subString)
                repetitionOfWords.append(temp)
            }
            for repetition in repetitionOfWords {
                for(_, value) in repetition {
                    if value > 1 {
                        tempWordRepetition = tempWordRepetition + 1
                    }
                }
            }
            
            totalWordsInSentenceCounter.append(totalWordCount)
            repetitionOfWordsCounter.append(tempWordRepetition)
            vocabsInSentenceCounter.append(vocabsInSentence)
            index = index + 1
        }
        //Punctuating Strings
        for subString in punctuatedStrings {
            topicSeparatedBySentences.append(subString.components(separatedBy: "."))
            numberOfSentences = numberOfSentences + subString.components(separatedBy: ".").count
        }
        //getting Hypothetical Situations
        for subString in topicSeparatedBySentences {
            for subStringSentence in subString {
                if subStringSentence == " " {
                    continue
                }
                if (subStringSentence.lowercased().range(of:"if") != nil) && (subStringSentence.lowercased().range(of:"will") != nil) {
                    hypotheticalSituation = hypotheticalSituation + 1
                }
                else if (subStringSentence.lowercased().range(of:"if") != nil) && (subStringSentence.lowercased().range(of:"would") != nil) {
                    hypotheticalSituation = hypotheticalSituation + 1
                }
                else if (subStringSentence.lowercased().range(of:"if") != nil) && (subStringSentence.lowercased().range(of:"would have") != nil){
                    hypotheticalSituation = hypotheticalSituation + 1
                }
                //getting modal verbs
                if  (subStringSentence.lowercased().range(of:"must") != nil) ||
                    (subStringSentence.lowercased().range(of:"must not") != nil) ||
                    (subStringSentence.lowercased().range(of:"can") != nil) ||
                    (subStringSentence.lowercased().range(of:"could") != nil) ||
                    (subStringSentence.lowercased().range(of:"may") != nil) ||
                    (subStringSentence.lowercased().range(of:"might") != nil) ||
                    (subStringSentence.lowercased().range(of:"need not") != nil) ||
                    (subStringSentence.lowercased().range(of:"should") != nil) ||
                    (subStringSentence.lowercased().range(of:"ought to") != nil) ||
                    (subStringSentence.lowercased().range(of:"had better") != nil) {
                    
                    modalVerbs = modalVerbs + 1
                }
            }
            //getting collocations
            for subStringSentences in subString {
                if subStringSentences == " " {
                    continue
                }
                let collocations = detectingCollocationsInSentence(for: subStringSentences)
                collocationsInSentences.append(collocations)
            }
        }
        finalizeResult()
    }

//MARK: Finalize Result
    @available(iOS 11.0, *)
    func finalizeResult() {
        
//MARK: FC
        //Frequencies count
        var frequencyCounter = 0
        var frequencyResult  : Double = 0.0
        var delayed : Double = 0.0
        for indexedFrequencies in topicFrequencies {
            frequencyCounter = frequencyCounter + indexedFrequencies.count
            for frequency in indexedFrequencies {
                if frequency > 50 {
                    frequencyResult = frequencyResult + frequency
                } else {
                    delayed = delayed + frequency
                }
            }
        }
        frequencyResult = frequencyResult/Double(frequencyCounter)
        let frequencyDelayedResult = delayed/Double(frequencyCounter)
        
        if (frequencyResult > 100) {
            frequencyCounter = 0
        } else if (frequencyResult > 90.00) {
            frequencyCounter = 2
        } else if (frequencyResult > 80.00) {
            frequencyCounter = 3
        } else if (frequencyResult > 70.00) {
            frequencyCounter = 4
        } else if (frequencyResult > 60.00) {
            frequencyCounter = 5
        } else if (frequencyResult > 50.00) {
            frequencyCounter = 6
        } else if (frequencyResult > 40.00) {
            frequencyCounter = 7
        } else if (frequencyResult > 30.00) {
            frequencyCounter = 8
        } else if (frequencyResult > 20.00) {
            frequencyCounter = 9
        }
        
        //Repeating Words
        var totalwords = 0
        var repetitionWords = 0
        for index in totalWordsInSentenceCounter{
            totalwords = totalwords + index
        }
        for index in repetitionOfWordsCounter {
            repetitionWords = repetitionWords + index
        }
//        _ = totalwords / repetitionWords
        
//MARK: LR
        //Range of Vocabulary
        var rangeOfVocabulary = 0
        for index in vocabsInSentenceCounter {
            rangeOfVocabulary = rangeOfVocabulary + index
        }

//MARK: GR
        //Collocations
        for collocations in collocationsInSentences {
            if let _ = collocations["Verb"], let _ = collocations["Adverb"] {
                collocationsInSentencesCounter = collocationsInSentencesCounter + 1
            }
            if let _ = collocations["Verb"], let _ = collocations["Noun"] {
                collocationsInSentencesCounter = collocationsInSentencesCounter + 1
            }
            if let _ = collocations["Noun"], let _ = collocations["Verb"] {
                collocationsInSentencesCounter = collocationsInSentencesCounter + 1
            }
            if let _ = collocations["Noun"], let _ = collocations["Noun"] {
                collocationsInSentencesCounter = collocationsInSentencesCounter + 1
            }
            if let _ = collocations["Adverb"], let _ = collocations["Adjective"] {
                collocationsInSentencesCounter = collocationsInSentencesCounter + 1
            }
            if let _ = collocations["Adjective"], let _ = collocations["Noun"] {
                collocationsInSentencesCounter = collocationsInSentencesCounter + 1
            }
        }

//MARK: calculate band
        let fcband = ((Double(frequencyCounter) + Double(repetitionWords)) / 2) * 0.25
        let grband = (Double(hypotheticalSituation + modalVerbs).truncatingRemainder(dividingBy: 2.0)) * 0.25
        let lrband = (Double(rangeOfVocabulary + collocationsInSentencesCounter) / 2) * 0.25
        let prband = (Double(totalwords + frequencyCounter) / 2) * 0.25
        
        let totalBand = fcband+grband+lrband+prband
        
        print("Pronounced Word: \(totalwords)\nRange of Vocabs: \(rangeOfVocabulary)\nFrequencies result: \(frequencyCounter)\nRepetition of words: \(repetitionWords)\nNumber of Sentences: \(numberOfSentences)\nHypthetical Situation: \(hypotheticalSituation)\nModal verbs: \(modalVerbs)")
        
        PKHUD.sharedHUD.hide()
        let endTest = self.storyboard?.instantiateViewController(withIdentifier: "EndTest") as! EndTestViewController
        endTest.categoryname = self.mainHeadingLabel.text!
        endTest.textToSpeech = self.topicNames
        endTest.pronouncedWords = totalwords
        endTest.rangeOfVocabulary = rangeOfVocabulary
        endTest.frequencyCounter = frequencyCounter
        endTest.repetitedWords = repetitionWords
        endTest.numberOfSentences = numberOfSentences
        endTest.hypotheticalSituation = hypotheticalSituation
        endTest.modalVerbs = modalVerbs
        endTest.collocations = collocationsInSentencesCounter
        endTest.delayedFrequency = Int(frequencyDelayedResult)
        
        //getting 25% of band
        endTest.frband = fcband
        endTest.grband = grband
        endTest.lrband = lrband
        endTest.prband = prband
        
        
        endTest.totalBand = totalBand
        
        
        self.present(endTest, animated: true, completion: nil)
    }
    
    func repetitionOfWordCheck(for text: String) -> [String: Int] {
        var count = 0
        var temp = [String: Int]()
        indexedTopicContent.enumerateSubstrings(in: indexedTopicContent.startIndex..<indexedTopicContent.endIndex, options: .byWords) { (subString, subStringRange, enclosingRange, stop) in
            
            if case let s? = subString{
                if s.caseInsensitiveCompare(text) == .orderedSame{
                    count = count + 1
                    temp = [text:count]
                }
            }
        }
        return temp
    }
    
    @available(iOS 11.0, *)
    func vocabsInStrings(for text: String) -> Int{
        vocabsInStringsCounter = 0
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, _ in
            if let tag = tag {
                if  tag.rawValue == "Noun" ||
                    tag.rawValue == "Verb" ||
                    tag.rawValue == "Pronoun" ||
                    tag.rawValue == "Adverb" ||
                    tag.rawValue == "Adjective" {
                    vocabsInStringsCounter = vocabsInStringsCounter + 1
                }
            }
        }
        return vocabsInStringsCounter
    }
    
    @available(iOS 11.0, *)
    func seperateStringByWords(for text: String) -> Int{
    seperateStringByWordsArray.removeAll()
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { tag, tokenRange, stop in
            let word = (text as NSString).substring(with: tokenRange)
            seperateStringByWordsArray.append(word)
        }
        return seperateStringByWordsArray.count
    }
    
    
    //21 - 01 - 2019
    @available(iOS 11.0, *)
    func detectingCollocationsInSentence(for text: String) -> [String: String]{
        var detectedCollocations = [String: String]()
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, _ in
            if let tag = tag {
                let word = (text as NSString).substring(with: tokenRange)
                if  tag.rawValue == "Noun" ||
                    tag.rawValue == "Verb" ||
                    tag.rawValue == "Adverb" ||
                    tag.rawValue == "Adjective" {
                    
                    detectedCollocations[tag.rawValue] = word
                    //collocationsInSentencesCounter = collocationsInSentencesCounter + 1
                }
            }
        }
        return detectedCollocations
    }
}
