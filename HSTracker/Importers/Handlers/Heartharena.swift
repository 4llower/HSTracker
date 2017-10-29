//
//  Heartharena.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import RegexUtil

struct HearthArena: HttpImporter {

    var siteName: String {
        return "HearthArena"
    }

    var handleUrl: RegexPattern {
        return "heartharena\\.com"
    }

    var preferHttps: Bool {
        return false
    }
    
    public static let iso8601StringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let classNode = doc.at_xpath("//h1[@class='class']"),
            let className = classNode.text?.components(separatedBy: " ").first,
            let playerClass = CardClass(rawValue: className.lowercased()) else {
                logger.error("Class not found")
                return nil
        }
        logger.verbose("Got class \(playerClass)")

        let deckName = String(format: NSLocalizedString("Arena %@ %@", comment: ""),
                              className, HearthArena.dateFormatter.string(from: Date()))
        logger.verbose("Got deck name \(deckName)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        for cardNode in doc.xpath("//ul[@class='deckList']/li") {
            if let qty = cardNode.at_xpath("span[@class='quantity']")?.text,
                let count = Int(qty),
                let cardName = cardNode.at_xpath("span[@class='name']")?.text,
                let card = Cards.by(englishName: cardName) {
                card.count = count
                logger.verbose("Got card \(card)")
                cards.append(card)
            }
        }
        return (deck, cards)
    }
}
