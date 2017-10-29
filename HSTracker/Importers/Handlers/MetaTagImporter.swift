//
//  MetaTagImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import RegexUtil

struct MetaTagImporter: HttpImporter {
    var siteName: String { return "" }
    var handleUrl: RegexPattern { return ".*" }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        let nodes = doc.xpath("//meta")

        let deck = Deck()

        guard let deckName = getMetaProperty(nodes: nodes, prop: "x-hearthstone:deck") else {
            print("****** deck name not found")
            logger.error("Deck name not found")
            return nil
        }
        print("****** Got deck name \(deckName)")
        logger.verbose("Got deck name \(deckName)")
        deck.name = deckName

        var cards: [Card] = []
        if let heroId = getMetaProperty(nodes: nodes, prop: "x-hearthstone:deck:hero"),
            let cardList = getMetaProperty(nodes: nodes, prop: "x-hearthstone:deck:cards")?
                .components(separatedBy: ","),
            let playerClass = Cards.hero(byId: heroId)?.playerClass {
            logger.verbose("Got class \(playerClass)")

            deck.playerClass = playerClass

            cards = cardList.flatMap {
                if let card = Cards.by(cardId: $0) {
                    card.count = 1
                    logger.verbose("Got card \(card)")
                    return card
                }

                return nil
            }

        } else if let deckString = getMetaProperty(nodes: nodes, prop: "x-hearthstone:deck:deckstring") {
            logger.verbose("****** Got deck string \(deckString)")
            guard let (playerClass, cardList) = DeckSerializer
                .deserializeDeckString(deckString: deckString) else {
                    logger.error("Card list not found")
                    return nil
            }

            deck.playerClass = playerClass
            cards = cardList
        } else {
            logger.error("Can't find a valid deck")
            return nil
        }

        return (deck, cards)
    }

    private func getMetaProperty(nodes: XPathObject, prop: String) -> String? {
        return nodes.filter({ $0["property"] ?? "" == prop }).first?["content"]
    }
    
}
