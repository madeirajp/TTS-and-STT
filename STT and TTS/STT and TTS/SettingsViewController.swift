//
//  SettingsViewController.swift
//  STT and TTS
//
//  Created by Emir haktan Ozturk on 2.12.2017.
//  Copyright © 2017 emirhaktan. All rights reserved.
//

import UIKit
import AVFoundation


protocol SettingsViewControllerDelegate {
    func didSaveSettings()
}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    let speechSettings = UserDefaults.standard
    
    var rate: Float!
    
    var pitch: Float!
    
    var volume: Float!
    
    var delegate: SettingsViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.cornerRadius = 15.0
        tableView.tableFooterView = UIView()
        rate = speechSettings.value(forKey: "rate") as! Float
        pitch = speechSettings.value(forKey: "pitch") as! Float
        volume = speechSettings.value(forKey: "volume") as! Float
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "TTS Settings"
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell")
        
        let keyLabel = cell?.contentView.viewWithTag(10) as? UILabel
        let valueLabel = cell?.contentView.viewWithTag(20) as? UILabel
        let slider = cell?.contentView.viewWithTag(30) as? CustomSlider
        
        var value: Float = 0.0
        switch indexPath.row {
        case 0:
            value = rate
            keyLabel?.text = "Rate"
            valueLabel?.text = NSString(format: "%.2f", rate) as String
            slider?.minimumValue = AVSpeechUtteranceMinimumSpeechRate
            slider?.maximumValue = AVSpeechUtteranceMaximumSpeechRate
            slider?.addTarget(self, action: #selector(handleSliderValueChange), for: UIControlEvents.valueChanged)
            slider?.sliderIdentifier = 100
            
        case 1:
            value = pitch
            keyLabel?.text = "Pitch"
            valueLabel?.text = NSString(format: "%.2f", pitch) as String
            slider?.minimumValue = 0.5
            slider?.maximumValue = 2.0
            slider?.addTarget(self, action: #selector(handleSliderValueChange), for: UIControlEvents.valueChanged)
            slider?.sliderIdentifier = 200
            
        default:
            value = volume
            keyLabel?.text = "Volume"
            valueLabel?.text = NSString(format: "%.2f", volume) as String
            slider?.minimumValue = 0.0
            slider?.maximumValue = 1.0
            slider?.addTarget(self, action: #selector(handleSliderValueChange), for: UIControlEvents.valueChanged)
            slider?.sliderIdentifier = 300
            
        }
        if slider?.value != value {
            slider?.value = value
        }
        return cell!
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < 3 {
            return 100.0
        }
        else{
            return 170.0
        }
    }
    @objc func handleSliderValueChange(sender: CustomSlider) {
        switch sender.sliderIdentifier {
        case 100:
            rate = sender.value
        case 200:
            pitch = sender.value
            
        default:
            volume = sender.value
        }
        self.tableView.reloadData()
    }
    
    @IBAction func saveSettings(_ sender: Any) {
        UserDefaults.standard.set(rate, forKey: "rate")
        UserDefaults.standard.set(pitch, forKey: "pitch")
        UserDefaults.standard.set(volume, forKey: "volume")
        UserDefaults.standard.synchronize()
        
        self.delegate.didSaveSettings()
        navigationController?.popViewController(animated: true)
    }
    
}
