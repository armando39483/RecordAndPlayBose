//
//  ViewController.swift
//  RecordAndPlayBose
//
//  Created by Armando Gonzalez on 3/7/19.
//  Copyright © 2019 Armando Gonzalez. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth

enum ButtonTag: Int {
    case playButton = 0, recordButtonTag
    var id: Int {
        return self.rawValue
    }
}

class ViewController: UIViewController {
    let songKeyPath = "currentSong"
    let audioRecordingFileName = "audio_recordAndPlayApp.m4a"
    
    let playButtonTag = ButtonTag(rawValue: 0)!
    let recordButtonTag = ButtonTag(rawValue: 1)!
    
    var playButton: UIButton!
    var recordButton: UIButton!
    var stackView: UIStackView!
    
    var audioSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var centralManager: CBCentralManager!
    var headPhonePeripheral: CBPeripheral!
    
    var recording: AVPlayerItem!
//    var audioPlayer: AVAudioPlayer!
    lazy var audioPlayer: AVQueuePlayer = self.makePlayer()
    lazy var song: [AVPlayerItem] = {
        let songName = ["FeelinGood"]
        return songName.map {
            let url = Bundle.main.url(forResource: $0, withExtension: "mp3")!
            return AVPlayerItem(url: url)
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        setupStackView()
        setupAudioSession()
        startScanningForPeripherals()
    }
    
    private func initialSetup() {
        view.backgroundColor = .white
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: getRecordingURL())
//        } catch {
//
//        }
//        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    private func setupStackView() {
        setupButtons()
        stackView = UIStackView(arrangedSubviews: [playButton,recordButton])
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 25
        stackView.distribution = .fill
        addCenterConstraints(for: stackView)
    }
    
    private func addCenterConstraints(for sv: UIStackView) {
        let centerX = NSLayoutConstraint(item: sv, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: sv, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        view.addConstraints([centerX,centerY])
    }

    private func setupButtons() {
        playButton = UIButton.init(type: .roundedRect)
        recordButton = UIButton.init(type: .roundedRect)
        view.addSubview(playButton)
        view.addSubview(recordButton)
        playButton.tag = playButtonTag.id
        recordButton.tag = recordButtonTag.id
        setHeightAndWidth(for: playButton)
        setHeightAndWidth(for: recordButton)
        playButton.setTitle("Play", for: .normal)
        playButton.setTitle("Stop", for: .selected)
        recordButton.setTitle("Record", for: .normal)
        recordButton.setTitle("Done", for: .selected)
        playButton.setTitleColor(.black, for: [.normal,.selected])
        recordButton.setTitleColor(.black, for: [.normal,.selected])
        playButton.backgroundColor = .green
        recordButton.backgroundColor = .red
        playButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        setHeightAndWidth(for: playButton)
        setHeightAndWidth(for: recordButton)
        playButton.addTarget(self, action: #selector(toggleButtons(_:)), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(toggleButtons(_:)), for: .touchUpInside)
//        playButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
//        recordButton.addTarget(self, action: #selector(recordButtonAction), for: .touchUpInside)
    }
    
    private func startScanningForPeripherals() {
        
    }
    
//    @objc func playButtonAction(_ button: UIButton!) {
//        toggleButtons(selected: button)
//        if button.isSelected && recording != nil {
//            audioPlayer(play: true)
//        } else {
//            audioPlayer(play: false)
//        }
//    }
//
//    @objc func recordButtonAction(_ button: UIButton!) {
//        toggleButtons(selected: button)
//        if button.isSelected {
//            startRecording()
//        } else {
//            finishRecording(success: true)
//        }
//    }
    
    @objc func toggleButtons(_ button: UIButton!) {
        switch (button == playButton, button.isSelected) {
        case (true,true):
            audioPlayer(play: false)
            playButton.isSelected = false
            recordButton.isEnabled = true
        case (true, false):
            playButton.isSelected = true
            recordButton.isEnabled = false
            audioPlayer(play: true)
        case (false, true):
            finishRecording(success: true)
            recordButton.isSelected = false
            playButton.isEnabled = true
        case (false, false):
            recordButton.isSelected = true
            playButton.isEnabled = false
            startRecording()
            
        }
//        guard let secondButton = button.tag == playButtonTag.id ? recordButton : playButton else { return }
//        if button.isSelected {
//            button.isSelected = false
//            secondButton.isEnabled = true
//        } else {
//            button.isSelected = true
//            secondButton.isEnabled = false
//        }
    }
    
    private func setHeightAndWidth(for button: UIButton) {
        let height = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25)
        let width = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 75)
        view.addConstraints([height,width])
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .allowBluetooth)
            try audioSession.setActive(true)
            audioSession.requestRecordPermission() {
                [unowned self] (allowed) in
                DispatchQueue.main.async {
                    if !allowed {
                        print("Permission denied: cannot record")
                    }
                }
            }
        } catch {
            print("Error occured while setting up audio session")
        }
    }
}

extension ViewController: AVAudioRecorderDelegate {
    private func startRecording() {
        let audioFileName = getDocumentsDirectory().appendingPathComponent("audio_recordAndPlayApp.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            print("Recording...")
        } catch {
            finishRecording(success: false)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
//    private func getRecordingAVPlayerItem() -> AVPlayerItem {
//        let url = getDocumentsDirectory().appendingPathComponent(audioRecordingFileName)
//        return AVPlayerItem(url: url)
//    }
    
    private func getRecordingURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return documentsURL.appendingPathComponent(audioRecordingFileName)
    }
    
    private func getRecordingAVPlayerItem() -> AVPlayerItem {
        let recordingFileURL = getRecordingURL()
        return AVPlayerItem(url: recordingFileURL)
    }
    
    private func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            print("Recording successful")
        } else {
            recording = nil
            print("Recording failure")
        }
    }
}

extension ViewController {
    private func makePlayer() -> AVQueuePlayer {
//    private func makePlayer() -> AVAudioPlayer? {
//        let player = AVQueuePlayer(items: song)
        
//        let url = getRecordingURL()
//        guard let player = try? AVAudioPlayer(contentsOf: url, fileTypeHint: "m4a") else { return nil }
        recording = getRecordingAVPlayerItem()
        let player = AVQueuePlayer(items: [recording])
        player.actionAtItemEnd = .advance
//        player.addObserver(self, forKeyPath: songKeyPath, options: [.new,.initial], context: nil)
        return player
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == songKeyPath, let player = object as? AVPlayer,
            let currentSong = player.currentItem?.asset as? AVURLAsset {
            // TODO: let label = "Playing recording"
            //noticeLabel.text = currentSong.url.lastPathComponent
            print("Playing song")
        }
    }
    
    private func audioPlayer(play: Bool) {
        if play {
            audioPlayer.play()
            print("Playing audio")
        } else {
            audioPlayer.pause()
            print("Audio paused")
        }
    }
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unauthorized:
            print("Central.state = unauthorized")
        case .unsupported:
            print("Central.state = unsupported")
        case .poweredOn:
            print("Central.state = poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
        case .poweredOff:
            print("Central.state = poweredOff")
        case .resetting:
            print("Central.state = resetting")
        case .unknown:
            print("Central.state = unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
//        headPhonesPeripheral = peripheral
//        headPhonePeripheral.delegate = self
//        centralManager.stopScan()
//        centralManager.connect(headPhonePeripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to headPhones")
        headPhonePeripheral.discoverServices(nil)
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = headPhonePeripheral.services else { return }
        
        services.forEach { (service) in
            print(service)
            print(service.characteristics ?? "characteristics are nil")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        characteristics.forEach { (characteristic) in
            print(characteristic)
        }
    }
}
