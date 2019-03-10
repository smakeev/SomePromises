//
//  ViewController.swift
//  SomePromises
//
//  Created by Sergey Makeev on 17/02/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

import UIKit

class Cat {
	var name: String?
	var color: String?
	weak var owner: CatOwner?
}

class CatOwner {
	var name: String?
	var cat: Cat?
}

class ViewController: UIViewController {
	var locContainer: LocContainer! = LocContainer()
	override func viewDidLoad() {
		super.viewDidLoad()
		locContainer.registerClass("Cat") {
										producer in
										let cat = Cat()
										if let name = producer.parameters["catName"] as? String {
											cat.name = name
										}
										if let color = producer.parameters["catColor"] as? String {
											cat.color = color
										}
										return cat
										}
					.registerClass("CatOwner") {
										producer in
			
										if let cat = producer.produceClass(name: "Cat") as? Cat {
											let catOwner = CatOwner()
											catOwner.name = "Sergey"
											catOwner.cat = cat
											cat.owner = catOwner
											return catOwner
										}
										return nil
		}
		
		//could be done later
		locContainer.registerParameters(
										["catName": "Mutex",
										 "catColor" : "gray"])
		
		let catOwner = locContainer.produceClass(name: "CatOwner") as? CatOwner
		print(catOwner ?? "Nobody")
		print(catOwner?.name ?? "No name")
		print(catOwner?.cat ?? "No cat")
		print(catOwner?.cat?.name ?? "No name for cat")
		print(catOwner?.cat?.color ?? "No color")
	}
}

