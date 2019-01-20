//This is a view controller written on Swift inside the Objective-c project to
//demonstrate usage of the Objective-c library part inside the swift code.

import UIKit

class AboutViewController : UIViewController {
	
	
	@IBOutlet weak var aboutTextLabel: UILabel!
	@IBOutlet weak var backButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	@IBAction func onBackPressed(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}
}

