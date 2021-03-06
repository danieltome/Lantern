//
//  PageInfoValidationResult.swift
//  Hoverlytics
//
//  Created by Patrick Smith on 28/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Ono


public enum PageInfoValidationResult {
	case Valid
	case NotRequested
	case Missing
	case Empty
	case Multiple
	case Invalid
}

private let whitespaceCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
private let nonWhitespaceCharacterSet = whitespaceCharacterSet.invertedSet

private func stringIsJustWhitespace(string: String) -> Bool {
	// Return range if non-whitespace characters are present, nil if no non-whitespace characters are present.
	return string.rangeOfCharacterFromSet(nonWhitespaceCharacterSet, options: [], range: nil) == nil
}

extension PageInfoValidationResult {
	init(validatedStringValue: ValidatedStringValue) {
		switch validatedStringValue{
		case .ValidString:
			self = .Valid
		case .NotRequested:
			self = .NotRequested
		case .Missing:
			self = .Missing
		case .Empty:
			self = .Empty
		case .Multiple:
			self = .Multiple
		case .Invalid:
			self = .Invalid
		}
	}
	
	static func validateContentsOfElements(elements: [ONOXMLElement]) -> PageInfoValidationResult {
		let validatedStringValue = ValidatedStringValue.validateContentOfElements(elements)
		return self.init(validatedStringValue: validatedStringValue)
	}
	
	static func validateMIMEType(MIMEType: String) -> PageInfoValidationResult {
		if stringIsJustWhitespace(MIMEType) {
			return .Missing
		}
		
		return .Valid
	}
}


public enum PageInfoValidationArea: Int {
	case MIMEType = 1
	case Title = 2
	case H1 = 3
	case MetaDescription = 4
	
	var title: String {
		switch self {
		case .MIMEType:
			return "MIME Type"
		case .Title:
			return "Title"
		case .H1:
			return "H1"
		case .MetaDescription:
			return "Meta Description"
		}
	}
	
	var isRequired: Bool {
		return true
	}
	
	static var allAreas = Set<PageInfoValidationArea>([.MIMEType, .Title, .H1, .MetaDescription])
}

extension PageInfo {
	public func validateArea(validationArea: PageInfoValidationArea) -> PageInfoValidationResult {
		switch validationArea {
		case .MIMEType:
			if let MIMEType = MIMEType {
				return PageInfoValidationResult.validateMIMEType(MIMEType.stringValue)
			}
		case .Title:
			if let pageTitleElements = contentInfo?.pageTitleElements {
				return PageInfoValidationResult.validateContentsOfElements(pageTitleElements)
			}
		case .H1:
			if let h1Elements = contentInfo?.h1Elements {
				return PageInfoValidationResult.validateContentsOfElements(h1Elements)
			}
		case .MetaDescription:
			if let metaDescriptionElements = self.contentInfo?.metaDescriptionElements {
				switch metaDescriptionElements.count {
				case 1:
					let element = metaDescriptionElements[0]
					let validatedStringValue = ValidatedStringValue.validateAttribute("content", ofElement: element)
					return PageInfoValidationResult(validatedStringValue: validatedStringValue)
				case 0:
					return .Missing
				default:
					return .Multiple
				}
			}
		}
		
		return .Missing
	}
}


public extension PageMapper {
	public func copyHTMLPageURLsWhichCompletelyValidateForType(type: BaseContentType) -> [NSURL] {
		let validationAreas = PageInfoValidationArea.allAreas
		let URLs = copyURLsWithBaseContentType(type, withResponseType: .Successful)
		
		return URLs.filter { URL in
			guard let pageInfo = self.loadedURLToPageInfo[URL] else { return false }
			
			let containsInvalidResult = validationAreas.contains { validationArea in
				return pageInfo.validateArea(validationArea) != .Valid
			}
			
			return !containsInvalidResult
		}
	}
	
	public func copyHTMLPageURLsForType(type: BaseContentType, failingToValidateInArea validationArea: PageInfoValidationArea) -> [NSURL] {
		let URLs = copyURLsWithBaseContentType(type, withResponseType: .Successful)
		
		return URLs.filter { URL in
			guard let pageInfo = self.loadedURLToPageInfo[URL] else { return false }
			
			switch pageInfo.validateArea(validationArea) {
			case .Valid:
				return false
			case .Missing:
				return validationArea.isRequired // Only invalid if it is required
			default:
				return true
			}
		}
	}
}
