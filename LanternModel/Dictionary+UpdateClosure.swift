//
//  Dictionary+UpdateClosure.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


extension Dictionary {
	mutating func updateValueForKey(key: Key, updater: ((previousValue: Value?) -> Value)) {
		let previousValue = self[key]
		self[key] = updater(previousValue: previousValue)
	}
}
