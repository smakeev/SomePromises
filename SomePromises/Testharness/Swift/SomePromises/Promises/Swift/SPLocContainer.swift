//
//  File.swift
//  SomePromises
//
//  Created by Sergey Makeev on 17/02/2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

import Foundation

protocol Producer {
	var  parameters: [String:Any] {get}
	func produce(className class:String) -> AnyObject?
}

class LocContainer: Producer{

	private(set) var parameters: [String:Any] = [String:Any]()
	func produce(className: String) -> AnyObject? {
		if let produceBlock = classes[className] {
			return produceBlock(self)
		}
		return nil
	}

	@discardableResult func registerClass(_ className:String, producingBlock:  @escaping (_:Producer) -> AnyObject?) -> LocContainer {
		classes[className] = producingBlock
		return self
	}
	
	@discardableResult func registerParameters(_ newParams:[String:Any]) -> LocContainer {
		newParams.keys.forEach { key in
			parameters[key] = newParams[key]
		}
		return self
	}

	private var classes: [String: (_:Producer)->AnyObject?]  = [:]
}
