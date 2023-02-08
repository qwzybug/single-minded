//
//  JukeboxProgramming.swift
//  Juke
//
//  Created by devin chalmers on 2/6/23.
//

import Foundation

class JukeboxProgram: ObservableObject {
    @Published var mapping: [JukeboxSlotContents:Disc] = [:]

    func place(_ disc: Disc, at slot: JukeboxSlotContents) {
        NSLog("Placing \(disc) in \(slot)")
        if let oldSlot = mapping.first(where: { (_, value) in value == disc }) {
            NSLog("Removing disc from slot \(oldSlot.key)")
            mapping.removeValue(forKey: oldSlot.key)
        }
        mapping[slot] = disc
    }
}

enum JukeboxSlotContents: Hashable, Equatable {
    case song(Character, Int)
    case blank

    var stringA: String {
        switch self {
        case let .song(character, idx): return "\(character)\(idx)"
        case .blank: return ""
        }
    }

    var stringB: String {
        switch self {
        case let .song(character, idx): return "\(character)\(idx + 1)"
        case .blank: return ""
        }
    }

    static func bank(_ indexCharacter: Character, count: Int) -> [JukeboxSlotContents] {
        return (0 ..< count).map { idx in
            JukeboxSlotContents.song(indexCharacter, 2 * idx + 1)
        }
    }
}

struct JukeboxLayout {
    let sections: [JukeboxSection?]
    let columns: Int

    static var seeburgM100: Self = {
        let abSlots = JukeboxSlotContents.bank("A", count: 5) + JukeboxSlotContents.bank("B", count: 5)
        let cdSlots = JukeboxSlotContents.bank("C", count: 5) + JukeboxSlotContents.bank("D", count: 5)
        let efSlots = JukeboxSlotContents.bank("E", count: 5) + JukeboxSlotContents.bank("F", count: 5)
        let ghSlots = JukeboxSlotContents.bank("G", count: 5) + JukeboxSlotContents.bank("H", count: 5)

        let jSlots = JukeboxSlotContents.bank("J", count: 5).inserting(.blank, at: 2)
        let kSlots = JukeboxSlotContents.bank("K", count: 5).inserting(.blank, at: 5)

        let abSection = JukeboxSection(title: "HIT TUNES", slots: abSlots, rows: 5, cols: 2)
        let cdSection = JukeboxSection(title: "HIT TUNES", slots: cdSlots, rows: 5, cols: 2)
        let efSection = JukeboxSection(title: "HIT TUNES", slots: efSlots, rows: 5, cols: 2)
        let ghSection = JukeboxSection(title: "WESTERN SONGS", slots: ghSlots, rows: 5, cols: 2)
        let jSection = JukeboxSection(title: "CLASSICAL SELECTIONS", slots: jSlots, rows: 3, cols: 2)
        let kSection = JukeboxSection(title: "OLD FAVORITES", slots: kSlots, rows: 3, cols: 2)

        return JukeboxLayout(sections: [abSection, cdSection, efSection, ghSection, jSection, nil, nil, kSection], columns: 4)
    }()
}

struct JukeboxSection: Hashable, Equatable {
    let title: String
    let slots: [JukeboxSlotContents]
    let rows: Int
    let cols: Int
//    case bank(title: String, slots: [JukeboxSlotContents], rows: Int, cols: Int)
//    case blank

    func slot(_ row: Int, _ col: Int) -> JukeboxSlotContents {
//        switch self {
//        case .bank(_, let slots, let rows, _):
            let index = col * rows + row
            return index < slots.count ? slots[index] : .blank
//
//        case .blank:
//            return .blank
//        }
    }
}
