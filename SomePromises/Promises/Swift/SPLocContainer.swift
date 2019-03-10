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
	func produceClass(name class:String) -> AnyObject?
	func produceType(name class:String) -> Any?
}

class LocContainer: Producer{

	private(set) var parameters: [String:Any] = [String:Any]()
	func produceClass(name: String) -> AnyObject? {
		if let produceBlock = classes[name] {
			return produceBlock(self)
		}
		return nil
	}
	
	func produceType(name: String) -> Any? {
		if let produceBlock = types[name] {
			return produceBlock(self)
		}
		return nil
	}
	
	@discardableResult func registerType(_ typeName:String, producingBlock: @escaping (_:Producer) -> Any?) -> LocContainer {
		types[typeName] = producingBlock
		return self
	}

	@discardableResult func registerClass(_ className:String, producingBlock: @escaping (_:Producer) -> AnyObject?) -> LocContainer {
		classes[className] = producingBlock
		return self
	}
	
	@discardableResult func registerParameters(_ newParams:[String:Any]) -> LocContainer {
		newParams.keys.forEach { key in
			parameters[key] = newParams[key]
		}
		return self
	}

	private var classes: [String: (_:Producer)->AnyObject?] = [:]
	private var types: [String: (_:Producer)->Any?] = [:]
}
