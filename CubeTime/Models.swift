import Foundation
import SwiftUI

struct CalculatedAverage: Identifiable, Comparable {
    let id = UUID()
    var name: String

    //    let discardedIndexes: [Int]
    let average: Double?
    let accountedSolves: [Solve]?
    let totalPen: Penalty
    let trimmedSolves: [Solve]?
    
    static func < (lhs: CalculatedAverage, rhs: CalculatedAverage) -> Bool {
        #warning("TODO:  merge with that one sort function")
        if lhs.totalPen == .dnf && rhs.totalPen != .dnf {
            return true
        } else if lhs.totalPen != .dnf && rhs.totalPen == .dnf {
            return false
        } else {
            if let lhsa = lhs.average {
                if let rhsa = rhs.average {
//                    return timeWithPlusTwo(lhsa, pen: lhs.totalPen) < timeWithPlusTwo(rhsa, pen: rhs.totalPen)
                    return lhsa < rhsa
                } else {
                    return true
                }
            } else {
                return false
            }
        }
    }
}

struct Average: Identifiable, Comparable {
    let id = UUID()
    
    let average: Double
    let penalty: Penalty
    
    static func < (lhs: Average, rhs: Average) -> Bool {
        if (lhs.penalty == .dnf) { return false }
        if (rhs.penalty == .dnf) { return true }
        
        return lhs.average < rhs.average
    }
}


extension Solve {
    var timeText: String {
        get {
            return formatSolveTime(secs: self.time, penalty: Penalty(rawValue: self.penalty)!)
        }
    }
}


extension Session {
    var typeName: String {
        get {
            switch (SessionType(rawValue: sessionType)!) {
            case .standard:
                return PUZZLE_TYPES[Int(scrambleType)].name
            case .algtrainer:
                return String(localized: "Algorithm Trainer")
            case .multiphase:
                return String(localized: "Multiphase")
            case .playground:
                return String(localized: "Playground")
            case .compsim:
                return String(localized: "Compsim")
            }
        }
    }
    
    @ViewBuilder func icon(size: CGFloat=24) -> some View {
        let scaledSize = size * 0.88
        
        switch (SessionType(rawValue: sessionType)!) {
        case .standard:
            Image(PUZZLE_TYPES[Int(scrambleType)].imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        case .algtrainer:
            Image(systemName: "command.square").font(.system(size: scaledSize))
        case .multiphase:
            Image(systemName: "square.stack").font(.system(size: scaledSize))
        case .playground:
            Image(systemName: "square.on.square").font(.system(size: scaledSize))
        case .compsim:
            Image(systemName: "globe.asia.australia").font(.system(size: scaledSize))
        }
    }
    
    var shortcutName: String {
        get {
            let scrname = PUZZLE_TYPES[Int(scrambleType)].name
            switch (SessionType(rawValue: sessionType)!) {
            case .standard:
                return scrname
            case .algtrainer:
                return self.typeName + " - " + scrname
            case .multiphase:
                return self.typeName + " - " + scrname
            case .playground:
                return self.typeName
            case .compsim:
                return self.typeName + " - " + scrname
            }
        }
    }
}

extension CompSimSolveGroup {
    var orderedSolves: [CompSimSolve] {
        // CSTODO + date order
        return (self.solves!.allObjects as! [CompSimSolve]).sorted(by: {$0.date! > $1.date!})
    }
    
    var avg: CalculatedAverage? {
        return StopwatchManager.getCalculatedAverage(forSolves: self.solves!.allObjects as! [Solve], name: String(localized: "Compsim Group"), isCompsim: true)
    }
}

extension Solve: Comparable {
    var timeIncPen: Double {
        get {
            return self.time + (self.penalty == Penalty.plustwo.rawValue ? 2 : 0)
        }
    }
    
    var timeIncPenDNFMax: Double {
        get {
            return (self.penalty == Penalty.dnf.rawValue
                    ? Double.infinity
                    : (self.time + (self.penalty == Penalty.plustwo.rawValue ? 2 : 0)))
        }
    }
    
    public static func < (lhs: Solve, rhs: Solve) -> Bool {
        return lhs.timeIncPen < rhs.timeIncPen
    }

    // I don't know if i need both but better safe than sorry
    public static func > (lhs: Solve, rhs: Solve) -> Bool {
        return lhs.timeIncPen > rhs.timeIncPen
    }
}


enum Penalty: Int16, Hashable {
    case none
    case plustwo
    case dnf
    
    func exportName() -> String? {
        return switch self {
        case .plustwo:
            "PlusTwo"
        case .dnf:
            "DNF"
        default:
            nil
        }
    }
}

enum SessionType: Int16 {
    case standard
    case algtrainer
    case multiphase
    case playground
    case compsim
}


// MARK: - Wrappers
struct PuzzleType {
    let name: String
    let cstimerName: String
    let imageName: String
//    let puzzle: OrgWorldcubeassociationTnoodleScramblesPuzzleRegistry
}


struct AppZoom: RawRepresentable, Identifiable {
    static let allCases = [DynamicTypeSize.xSmall,
                           DynamicTypeSize.small,
                           DynamicTypeSize.medium,
                           DynamicTypeSize.large,
                           DynamicTypeSize.xLarge,
                           DynamicTypeSize.xxLarge,
                           DynamicTypeSize.xxxLarge,
    ]
    
    static private let appZoomNames: [DynamicTypeSize: String] = [
        DynamicTypeSize.xSmall: String(localized: "Extra Small"),
        DynamicTypeSize.small: String(localized: "Small"),
        DynamicTypeSize.medium: String(localized: "Medium"),
        DynamicTypeSize.large: String(localized: "Large (Default)"),
        DynamicTypeSize.xLarge: String(localized: "Extra Large"),
        DynamicTypeSize.xxLarge: String(localized: "Extra Extra Large"),
        DynamicTypeSize.xxxLarge: String(localized: "Extra Extra Extra Large"),
    ]
    
    typealias RawValue = Int
    
    
    let size: DynamicTypeSize
    let name: String
    
    var rawValue: RawValue
    
    init(rawValue: RawValue) {
        // Couldn't figure out a nice way to do this with guard let
        self.rawValue = rawValue
        self.size = Self.allCases[rawValue]
        self.name = Self.appZoomNames[size]!
    }
    
    
    var id: Int {
        return rawValue
    }
}


struct SessionTypeIcon {
    var size: CGFloat = 26
    var iconName: String = ""
    var padding: (leading: CGFloat, trailing: CGFloat) = (8, 4)
    var weight: Font.Weight = .regular
}
