//
//  MainWindowController.swift
//  Hoverlytics for Mac
//
//  Created by Patrick Smith on 29/03/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import HoverlyticsModel


class MainWindowController: NSWindowController, NSToolbarDelegate {
	
	let mainState = HoverlyticsModel.MainState()
	let modelManager = HoverlyticsModel.ModelManager.sharedManager
	
	var mainViewController: ViewController! {
		return contentViewController as ViewController
	}
	
	var toolbarAssistant: MainWindowToolbarAssistant!
	@IBOutlet var toolbar: NSToolbar! {
		didSet {
			toolbarAssistant = MainWindowToolbarAssistant(toolbar: toolbar, mainState: mainState, modelManager: modelManager)
			
			toolbarAssistant.prepareNewSiteButton = { [unowned self] button in
				button.target = self.mainViewController
				button.action = "showAddSite:"
			}
			
			toolbarAssistant.prepareSiteSettingsButton = { [unowned self] button in
				button.target = self.mainViewController
				button.action = "showSiteSettings:"
			}
		}
	}

    override func windowDidLoad() {
		println("wc windowDidLoad")
        super.windowDidLoad()
		
		if let window = window {
			window.titleVisibility = .Hidden
		}
		
		mainViewController.modelManager = modelManager
		mainViewController.mainState = mainState
    }
	
	@IBAction func focusOnSearchPagesField(sender: AnyObject?) {
		toolbarAssistant.focusOnSearchPagesField(sender)
	}
}


class MainWindowToolbarAssistant: NSObject, NSToolbarDelegate {
	let toolbar: NSToolbar
	let mainState: HoverlyticsModel.MainState
	let modelManager: HoverlyticsModel.ModelManager
	
	init(toolbar: NSToolbar, mainState: HoverlyticsModel.MainState, modelManager: HoverlyticsModel.ModelManager) {
		self.toolbar = toolbar
		self.mainState = mainState
		self.modelManager = modelManager
		
		super.init()
		
		toolbar.delegate = self
		
		startObservingModelManager()
	}
	
	deinit {
		stopObservingModelManager()
	}
	
	
	func startObservingModelManager() {
		let nc = NSNotificationCenter.defaultCenter()
		let mainQueue = NSOperationQueue.mainQueue()
		
		func addObserver(notificationIdentifier: HoverlyticsModel.ModelManagerNotification, block: (NSNotification!) -> Void) -> NSObjectProtocol {
			return nc.addObserverForName(notificationIdentifier.notificationName, object: modelManager, queue: mainQueue, usingBlock: block)
		}
		
		addObserver(.AllSitesDidChange) { (notification) in
			self.updateUIForSites()
		}
	}
	
	func stopObservingModelManager() {
		let nc = NSNotificationCenter.defaultCenter()
	}
	
	
	var sitesPopUpButton: NSPopUpButton!
	let siteTag: Int = 1
	
	func updateSitesPopUpButton() {
		if sitesPopUpButton == nil {
			return
		}
		
		func removeNextItemWithTag(tag: Int) -> Bool {
			let index = sitesPopUpButton.indexOfItemWithTag(tag)
			if index == -1 {
				return false
			}
			else {
				sitesPopUpButton.removeItemAtIndex(index)
				return true
			}
		}
		
		while removeNextItemWithTag(siteTag) {}
		
		sitesPopUpButton.target = self
		sitesPopUpButton.action = "chosenSiteDidChange:"
		
		let menu = sitesPopUpButton.menu!
		if let allSites = modelManager.allSites {
			for site in allSites {
				let menuItem = NSMenuItem(title: site.name, action: nil, keyEquivalent: "")
				menuItem.representedObject = site
				menuItem.tag = siteTag
				menu.insertItem(menuItem, atIndex: 0)
			}
		}
		else {
			let menuItem = NSMenuItem(title: "No Sites", action: nil, keyEquivalent: "")
			menuItem.tag = siteTag
			menu.insertItem(menuItem, atIndex: 0)
		}
		
		updateChosenSiteState()
	}
	
	func updateUIForSites() {
		let hasSites = modelManager.allSites?.count > 0
		
		//sitesPopUpButton?.enabled = hasSites
		siteSettingsButton?.enabled = hasSites
		siteSettingsButton?.hidden = !hasSites
		
		updateSitesPopUpButton()
	}
	
	@objc @IBAction func chosenSiteDidChange(sender: NSPopUpButton) {
		updateChosenSiteState()
	}

	func updateChosenSiteState() {
		if let selectedItem = sitesPopUpButton.selectedItem {
			if let site = selectedItem.representedObject as? Site {
				mainState.chosenSite = site
			}
		}
	}
	
	typealias PrepareButtonCallback = (NSButton) -> Void
	
	var addSiteButton: NSButton!
	var prepareNewSiteButton: PrepareButtonCallback?
	
	var siteSettingsButton: NSButton!
	var prepareSiteSettingsButton: PrepareButtonCallback?
	
	
	var searchPagesField: NSSearchField!
	@IBAction func focusOnSearchPagesField(sender: AnyObject?) {
		if let searchPagesField = searchPagesField {
			searchPagesField.window!.makeFirstResponder(searchPagesField)
		}
	}
	
	
	func toolbarWillAddItem(notification: NSNotification) {
		let userInfo = notification.userInfo!
		let toolbarItem = userInfo["item"] as NSToolbarItem
		let itemIdentifier = toolbarItem.itemIdentifier
		var sizeToFit = false
		
		if itemIdentifier == "newSiteButton" {
			addSiteButton = toolbarItem.view as NSButton
			prepareNewSiteButton?(addSiteButton)
		}
		else if itemIdentifier == "chosenSite" {
			sitesPopUpButton = toolbarItem.view as NSPopUpButton
			updateUIForSites()
			//updateSitesPopUpButton()
		}
		else if itemIdentifier == "siteSettingsButton" {
			siteSettingsButton = toolbarItem.view as NSButton
			sizeToFit = true
			prepareSiteSettingsButton?(siteSettingsButton)
			updateUIForSites()
		}
		else if itemIdentifier == "searchPages" {
			searchPagesField = toolbarItem.view as NSSearchField
		}
		
		if sizeToFit {
			let fittingSize = toolbarItem.view!.fittingSize
			toolbarItem.minSize = fittingSize
			toolbarItem.maxSize = fittingSize
		}
	}
}