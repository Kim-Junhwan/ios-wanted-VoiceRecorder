//
//  RecordVoiceViewController.swift
//  VoiceRecorder
//
//  Created by hayeon on 2022/06/27.
//

protocol RecordVoiceDelegate : AnyObject{
    func updateList()
}

import UIKit
class RecordVoiceViewController: UIViewController {

    weak var delegate : RecordVoiceDelegate?
    var recordVoiceManager : RecordVoiceManager!
    var drawWaveFormManager : DrawWaveFormManager!
    var playVoiceManager : PlayVoiceManager!
    var audioSessionManager = AudioSessionManager()
    var isHour = false
        
    let waveFormView : UIView = {
        let waveFormView = UIView()
        waveFormView.translatesAutoresizingMaskIntoConstraints = false
        waveFormView.frame.size.width = CGFloat(FP_INFINITE)
        return waveFormView
    }()
    
    let frequencyLabel : UILabel = {
        let frequencyLabel = UILabel()
        frequencyLabel.translatesAutoresizingMaskIntoConstraints = false
        return frequencyLabel
    }()
    
    let frequencySlider : UISlider = {
        let frequencySlider = UISlider()
        frequencySlider.translatesAutoresizingMaskIntoConstraints = false
        frequencySlider.isContinuous = false
        frequencySlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        frequencySlider.minimumValue = 8000
        frequencySlider.maximumValue = 44100
        return frequencySlider
    }()
    
    let progressTimeLabel : UILabel = {
        let progressTimeLabel = UILabel()
        progressTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        return progressTimeLabel
    }()
    
    let buttonStackView : UIStackView = {
        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 30
        return buttonStackView
    }()
    
    let record_start_stop_button : UIButton = {
        let record_start_stop_button = UIButton()
        record_start_stop_button.translatesAutoresizingMaskIntoConstraints = false
        record_start_stop_button.addTarget(self, action: #selector(tab_record_start_stop_Button), for: .touchUpInside)
        record_start_stop_button.setPreferredSymbolConfiguration(.init(pointSize: 40), forImageIn: .normal)
        return record_start_stop_button
    }()
    
    var recordFile_ButtonStackView : UIStackView = {
        let recordFile_ButtonStackView = UIStackView()
        recordFile_ButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        recordFile_ButtonStackView.axis = .horizontal
        recordFile_ButtonStackView.spacing = 20
        return recordFile_ButtonStackView
    }()
    
    var recordFile_play_PauseButton: UIButton = {
        let recordFile_play_PauseButton = UIButton()
        recordFile_play_PauseButton.translatesAutoresizingMaskIntoConstraints = false
        recordFile_play_PauseButton.setPreferredSymbolConfiguration(.init(pointSize: 30), forImageIn: .normal)
        recordFile_play_PauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        recordFile_play_PauseButton.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
        return recordFile_play_PauseButton
    }()
    
    var forwardFive: UIButton = {
        let forwardFive = UIButton()
        forwardFive.translatesAutoresizingMaskIntoConstraints = false
        forwardFive.setPreferredSymbolConfiguration(.init(pointSize: 30), forImageIn: .normal)
        forwardFive.setImage(UIImage(systemName: "goforward.5"), for: .normal)
        forwardFive.addTarget(self, action: #selector(tabForward), for: .touchUpInside)
        return forwardFive
    }()
    
    var backwardFive: UIButton = {
        let backwardFive = UIButton()
        backwardFive.translatesAutoresizingMaskIntoConstraints = false
        backwardFive.setPreferredSymbolConfiguration(.init(pointSize: 30), forImageIn: .normal)
        backwardFive.setImage(UIImage(systemName: "gobackward.5"), for: .normal)
        backwardFive.addTarget(self, action: #selector(tabBackward), for: .touchUpInside)
        return backwardFive
    }()
    
    @objc func tab_record_start_stop_Button() {
        if recordVoiceManager.isRecording() {
            var time = progressTimeLabel.text!
            if !isHour{
                time = time[0..<5]
            }
            drawWaveFormManager.stopDrawing(in: waveFormView)
            recordVoiceManager.stopRecording(time: time) {
                self.delegate?.updateList()
                self.playVoiceManager.setNewScheduleFile()
            }
            record_start_stop_button.setImage(UIImage(systemName: "circle.fill"), for: .normal)
            record_start_stop_button.tintColor = .red
            setUIAfterRecording()
            print("recording stop")
        } else {
            recordVoiceManager.startRecording()
            drawWaveFormManager.startDrawing(of: recordVoiceManager.recorder!, in: waveFormView)
            record_start_stop_button.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            record_start_stop_button.tintColor = .black
            setUIBeforeRecording()
            print("recording start")
        }
    }
    
    @objc func sliderValueChanged() {
        audioSessionManager.setSampleRate(Double(frequencySlider.value))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawWaveFormManager.delegate = self
        recordVoiceManager.delegate = self
        playVoiceManager.delegate = self
        audioSessionManager.setSampleRate(44100)

        setView()
        autoLayout()
        setUI()
    }
    
    func setView() {
        self.view.addSubview(waveFormView)
        
        self.view.addSubview(frequencyLabel)
        self.view.addSubview(frequencySlider)
        self.view.addSubview(progressTimeLabel)
        
        self.view.addSubview(buttonStackView)
        self.view.addSubview(recordFile_ButtonStackView)
        for item in [ backwardFive, recordFile_play_PauseButton, forwardFive ]{
            recordFile_ButtonStackView.addArrangedSubview(item)
        }
        
        self.buttonStackView.addArrangedSubview(record_start_stop_button)
        self.buttonStackView.addArrangedSubview(recordFile_ButtonStackView)
        
    }
    
    func autoLayout() {
        NSLayoutConstraint.activate([
            waveFormView.topAnchor.constraint(equalToSystemSpacingBelow: self.view.topAnchor, multiplier: 10),
            waveFormView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            waveFormView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.15),
            
            frequencyLabel.topAnchor.constraint(equalToSystemSpacingBelow: waveFormView.bottomAnchor, multiplier: 2),
            frequencyLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
            frequencyLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            frequencySlider.topAnchor.constraint(equalTo: frequencyLabel.bottomAnchor),
            frequencySlider.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
            frequencySlider.heightAnchor.constraint(equalTo: waveFormView.heightAnchor, multiplier: 0.5),
            frequencySlider.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            progressTimeLabel.topAnchor.constraint(equalTo: frequencySlider.bottomAnchor),
            progressTimeLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            buttonStackView.topAnchor.constraint(equalTo: progressTimeLabel.bottomAnchor, constant: 30),
//            buttonStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
//            buttonStackView.heightAnchor.constraint(equalTo: waveFormView.heightAnchor, multiplier: 0.9),
            buttonStackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
//            record_start_stop_button.heightAnchor.constraint(equalTo: buttonStackView.heightAnchor),
//            record_start_stop_button.widthAnchor.constraint(equalTo: record_start_stop_button.heightAnchor),
            
//            recordFile_ButtonStackView.centerYAnchor.constraint(equalTo: record_start_stop_button.centerYAnchor),
        ])
    }
    
    func setUI() {
        frequencyLabel.text = "cutoff frequency"
        frequencySlider.tintColor = .blue
        frequencySlider.value = 44100
        progressTimeLabel.text = "00:00:00"
        record_start_stop_button.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        record_start_stop_button.tintColor = .red
        recordFile_ButtonStackView.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if recordVoiceManager.isRecording(){
            recordVoiceManager.stopRecording(time: progressTimeLabel.text!) {
                self.drawWaveFormManager.stopDrawing(in: self.waveFormView)
                self.delegate?.updateList()
            }
        }
    }
    
    func setUIAfterRecording(){
        recordFile_ButtonStackView.isHidden = false
    }
    
    func setUIBeforeRecording(){
        recordFile_ButtonStackView.isHidden = true
    }
    
    @objc func tabForward(){
        playVoiceManager.forwardFiveSecond()
    }
    
    @objc func tabBackward(){
        playVoiceManager.backwardFiveSecond()
    }
    
    @objc func tapButton(){
        if playVoiceManager.isPlay{
            playVoiceManager.stopAudio()
            recordFile_play_PauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        }else{
            playVoiceManager.playAudio()
            recordFile_play_PauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
        }
    }

}

// MARK: DrawWaveFormManagerDelegate

extension RecordVoiceViewController : DrawWaveFormManagerDelegate {
    
    func moveWaveFormView(_ step: CGFloat) {
        
        UIView.animate(withDuration: 1/14, animations: {
            self.waveFormView.transform = CGAffineTransform(translationX: -step, y: 0)
        })
    }
    
    func resetWaveFormView() {
        self.waveFormView.transform = CGAffineTransform(translationX: 0, y: 0)
    }
}

// MARK: RecordVoiceManagerDelegate

extension RecordVoiceViewController : RecordVoiceManagerDelegate {
    
    func updateCurrentTime(_ currentTime : TimeInterval) {
        self.progressTimeLabel.text = currentTime.getStringTimeInterval()
    }
}

extension RecordVoiceViewController : PlayVoiceDelegate{
    func playEndTime() {
        playVoiceManager.isPlay = false
        DispatchQueue.main.async {
            self.recordFile_play_PauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        }
    }
}

extension TimeInterval{

    func getStringTimeInterval() -> String {

        let seconds = self
        let hour = Int(seconds) / (60 * 60)
        let min = Int(seconds) / 60
        let sec = Int(seconds) % 60
        let cen = Int(seconds * 100) % 100
        // centisecond : 10 밀리초
        print(hour)
        print(min)
        print(seconds)
        if hour == 0{
            let formatString = "%0.2d:%0.2d:%0.2d"
            return String(format: formatString, min, sec, cen)
        }else{
            let formatString = "%0.2d:%0.2d:%0.2d"
            return String(format: formatString, hour, min, sec)
        }
        
    }
}

extension String {
    subscript(_ range: Range<Int>) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let toIndex = self.index(self.startIndex,offsetBy: range.endIndex)
        return String(self[fromIndex..<toIndex])
    }
}
