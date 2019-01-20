//
//  InterfaceController.swift
//  SomeNews Whatchkit App Extension
//
//  Created by Sergey Makeev on 09/12/2018.
//  Copyright © 2018 SOME projects. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

	@IBOutlet weak var newsFoundLabel: WKInterfaceLabel!
	
	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        super.willActivate()
        newsFoundLabel.setText("News Found: 15")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
