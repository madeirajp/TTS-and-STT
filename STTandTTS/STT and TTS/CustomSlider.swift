//
//  CustomSlider.swift
//  STT and TTS
//
//  Created by Emir haktan Ozturk on 2.12.2017.
//  Copyright © 2017 emirhaktan. All rights reserved.
//

import UIKit

class CustomSlider: UISlider {
    
    var sliderIdentifier: Int!
    
    required init() {
        super.init(frame: CGRect.zero)
        sliderIdentifier = 0
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sliderIdentifier = 0
    }
    
}

