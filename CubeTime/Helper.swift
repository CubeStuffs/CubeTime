import Foundation
import SwiftUI
import UIKit
import Combine



extension CGSize {
    public init(_ svgdimen: OrgWorldcubeassociationTnoodleSvgliteDimension) {
        self.init(width: Int(svgdimen.getWidth()), height: Int(svgdimen.getHeight()))
    }
}

extension OrgWorldcubeassociationTnoodleSvgliteDimension {
    public convenience init(_ cgsize: CGSize) {
        self.init(int: jint(cgsize.width), with: jint(cgsize.height))
    }
}


public extension UIDevice {
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }()
}


extension UIColor {
    func colorsEqual (_ rhs: UIColor) -> Bool {
        var sred: CGFloat = 0
        var sgreen: CGFloat = 0
        var sblue: CGFloat = 0
        
        var rred: CGFloat = 0
        var rgreen: CGFloat = 0
        var rblue: CGFloat = 0
        

        self.getRed(&sred, green: &sgreen, blue: &sblue, alpha: nil)
        rhs.getRed(&rred, green: &rgreen, blue: &rblue, alpha: nil)

        return (Int(sred*255), Int(sgreen*255), Int(sblue*255)) == (Int(rred*255), Int(rgreen*255), Int(rblue*255))
    }
}


extension Color: RawRepresentable {
    public typealias RawValue = String
    init(_ hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255
        )
    }
    
    public init(rawValue: RawValue) {
        try! self.init(uiColor: NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: Data(base64Encoded: rawValue)!)!)
    }

    public var rawValue: RawValue {
        return try! NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false).base64EncodedString()
    }
}

extension UIScreen {
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

enum PenTypes: Int16 {
    case none
    case plustwo
    case dnf
}

enum SessionTypes: Int16 {
    case standard
    case algtrainer
    case multiphase
    case playground
    case compsim
}

struct DynamicText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scaledToFill()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}


struct AnimatingFontSize: AnimatableModifier {
    var fontSize: CGFloat

    var animatableData: CGFloat {
        get { fontSize }
        set { fontSize = newValue }
    }

    func body(content: Self.Content) -> some View {
        content
            .font(.system(size: self.fontSize, weight: .bold, design: .monospaced))
    }
}


@available(iOS 15, *)
struct ScaledCustomFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    
    var name: String
    var size: CGFloat
    var sf: Bool
    var weight: Font.Weight?
    
    func body(content: Content) -> some View {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        if sf {
            return content.font(.system(size: scaledSize, weight: weight ?? .regular, design: .default))
        } else {
            return content.font(.custom(name, size: scaledSize))
        }
    }
}

@available(iOS 15, *)
extension View {
    func scaledCustomFont(name: String, size: CGFloat, sf: Bool, weight: Font.Weight?) -> some View {
        return self.modifier(ScaledCustomFont(name: name, size: size, sf: sf, weight: weight))
    }
}



func formatSolveTime(secs: Double, dp: Int) -> String {
    if secs < 60 {
        return String(format: "%.\(dp)f", secs) // TODO set DP
    } else {
        let mins: Int = Int((secs / 60).rounded(.down))
        let secs = secs.truncatingRemainder(dividingBy: 60)
        
        return String(format: "%d:%0\(dp + 3).\(dp)f", mins, secs)
    }
}

func formatSolveTime(secs: Double, penType: PenTypes? = PenTypes.none) -> String {
    if penType == PenTypes.dnf {
        return "DNF"
    }
    let dp = UserDefaults.standard.integer(forKey: gsKeys.displayDP.rawValue)
    let secsfmt = penType == .plustwo ? ".\(dp)f+" : ".\(dp)f"
    if secs < 60 {
        return String(format: "%\(secsfmt)", secs) // TODO set DP
    } else {
        let mins: Int = Int((secs / 60).rounded(.down))
        let secs = secs.truncatingRemainder(dividingBy: 60)
        
        return String(format: "%d:%0\(dp + 3)\(secsfmt)", mins, secs)
    }
}


func formatLegendTime(secs: Double, dp: Int) -> String {
    
    if secs < 10 {
        return String(format: "%.\(dp)f", secs) // dp = 1
    } else if secs < 60 {
        return String(format: "%.\(dp-1)f", secs) // TODO set DP
    } else if secs < 600 {
        let mins: Int = Int((secs / 60).rounded(.down))
        let secs = Int(secs.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", mins, secs)
    } else {
        let mins: Int = Int((secs / 60).rounded(.down))
        return String(format: "%dm", mins)
    }
}


func getAvgOfSolveGroup(_ compsimsolvegroup: CompSimSolveGroup) -> CalculatedAverage? {
    
    let trim = 1
    
    guard let solves = compsimsolvegroup.solves!.array as? [Solves] else {return nil}
    
    if solves.count < 5 {
        return nil
    }
    
    let sorted = solves.sorted(by: Stats.sortWithDNFsLast)
    let trimmedSolves: [Solves] = sorted.prefix(trim) + sorted.suffix(trim)
    
    return CalculatedAverage(
        id: "Comp Sim",
        average: sorted.dropFirst(trim).dropLast(trim)
                .reduce(0, {$0 + timeWithPlusTwoForSolve($1)}) / Double(3),
        accountedSolves: sorted,
        totalPen: sorted.filter {$0.penalty == PenTypes.dnf.rawValue}.count >= trim * 2 ? .dnf : .none,
        trimmedSolves: trimmedSolves
    )
}



/// as the default textfield does not dynamically adjust its width according to the text
/// and instead is always set to the maximum width, this globalgeometrygetter is used
/// for the target input field on the timer view to change its width dynamically.

// source: https://stackoverflow.com/a/56729880/3902590
struct GlobalGeometryGetter: View {
    @Binding var rect: CGRect

    var body: some View {
        return GeometryReader { geometry in
            self.makeView(geometry: geometry)
        }
    }

    func makeView(geometry: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            self.rect = geometry.frame(in: .global)
        }

        return Rectangle().fill(Color.clear)
    }
}



// source: https://www.avanderlee.com/swiftui/conditional-view-modifier/
extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    public func gradientForeground(gradientSelected: Int) -> some View {
        self.overlay(getGradient(gradientArray: CustomGradientColours.gradientColours, gradientSelected: gradientSelected))
            .mask(self)
    }
}


struct PuzzleType {
    let name: String
    let puzzle: OrgWorldcubeassociationTnoodleScramblesPuzzleRegistry
}


let chtscramblesthatdontworkwithtnoodle: [OrgWorldcubeassociationTnoodleScramblesPuzzleRegistry] = [.SIX, .SEVEN, .SKEWB]
                    

let puzzle_types: [PuzzleType] = [
    PuzzleType(name: "2x2", puzzle: .TWO),
    PuzzleType(name: "3x3", puzzle: .THREE),
    PuzzleType(name: "4x4", puzzle: .FOUR_FAST),
    PuzzleType(name: "5x5", puzzle: .FIVE),
    PuzzleType(name: "6x6", puzzle: .SIX),
    PuzzleType(name: "7x7", puzzle: .SEVEN),
    PuzzleType(name: "Square-1", puzzle: .SQ1),
    PuzzleType(name: "Megaminx", puzzle: .MEGA),
    PuzzleType(name: "Pyraminx", puzzle: .PYRA),
    PuzzleType(name: "Clock", puzzle: .CLOCK),
    PuzzleType(name: "Skewb", puzzle: .SKEWB),
    
    // One hand
    PuzzleType(name: "3x3 OH", puzzle: .THREE),
    
    // Blind
    PuzzleType(name: "3x3 BLD", puzzle: .THREE),
    PuzzleType(name: "4x4 BLD", puzzle: .FOUR_FAST),
    PuzzleType(name: "5x5 BLD", puzzle: .FIVE),
]



// TODO convert to TextFieldStyle
struct TimeMaskTextField: ViewModifier {
    @Binding var text: String
    
    @State var userDotted = false
    
    var onReceiveAlso: ((String) -> Void)?
    func body(content: Content) -> some View {
        content
            .keyboardType(text.count > 2 ? .numberPad : .decimalPad)
            .onReceive(Just(text)) { newValue in
                refilter()
                
                onReceiveAlso?(text)
            }
    }
    
    func refilter() {
        var filtered: String!
        
        let dotCount = text.filter({ $0 == "."}).count
        
        
        // Let the user dot if the text is more than 1, less than six (0.xx.) and there are 2 dots where the last was just entered
        if text == "." || ( text.count > 1 && text.count < 6 && text.last! == "." && dotCount < 3 ) {
            userDotted = true
        } else if dotCount == 0 {
            userDotted = false
        }
        
        
        if userDotted {
            
            
            var removedfirstdot = !(dotCount == 2)
            
            filtered = String(
                text
                    .filter {
                        // Remove only first of 2 dots
                        if removedfirstdot {
                            return $0.isNumber || $0 == "."
                        } else {
                            if $0 == "." {
                                removedfirstdot = true
                                return false
                            } else {
                                return $0.isNumber
                            }
                        }
                    }
                    .replacingOccurrences(of: "^0+", with: "", options: .regularExpression) // Remove leading 0s
            )
            let dotindex = filtered.firstIndex(of: ".")!
            
            let from = filtered.index(dotindex, offsetBy: -2, limitedBy: filtered.startIndex) ?? filtered.startIndex
            let to = filtered.index(dotindex, offsetBy: 3, limitedBy: filtered.endIndex) ?? filtered.endIndex
            
            
            filtered = String(filtered[from..<to])
            
        } else {
            filtered = String(
                text.filter { $0.isNumber } // Remove a non numbers
                    .replacingOccurrences(of: "^0+", with: "", options: .regularExpression) // Remove leading 0s
                    .prefix(6)
            )
            if filtered.count > 2 {
                filtered.insert(".", at: filtered.index(filtered.endIndex, offsetBy: -2))
            } else if filtered.count > 0 {
                filtered = "0." + repeatElement("0", count: 2 - filtered.count) + filtered
            }
            if filtered.count > 5 {
                filtered.insert(":", at: filtered.index(filtered.endIndex, offsetBy: -5))
            }
        }
        
        text = filtered
    }
}

@inline(__always) func filteredStrFromTime(_ time: Double?) -> String {
    return time == nil ? "" : formatSolveTime(secs: time!, dp: 2)
}

func timeFromStr(_ formattedTime: String) -> Double? {
    if formattedTime.isEmpty {
        return nil
    }
    let separated = formattedTime.components(separatedBy: ":")
    let mins: UInt = separated.count > 1 ? UInt(separated[0])! : 0
    let secs: Double = Double(separated.last!) ?? 0
    
    return Double(mins) * 60 + secs
}

class SetValues {
    static let hasBottomBar = ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom)! > 0
}

class TimerTextColours {
    static let timerDefaultColour: Color = Color.primary
    static let timerDefaultColourDarkMode: Color = Color.primary
    static let timerHeldDownColour: Color = Color.red
    static let timerCanStartColour: Color = Color.green
    static let timerLoadingColor: Color = Color(uiColor: .systemGray)
}

class InspectionColours {
    static let eightColour: Color = Color(red: 234/255, green: 224/255, blue: 182/255)
    static let twelveColour: Color = Color(red: 234/255, green: 212/255, blue: 182/255)
    static let penaltyColour: Color = Color(red: 234/255, green: 194/255, blue: 192/255)
    
//    static let eightColour = 0xeae0b6
//    static let twelveColour = 0xead4b6
//    static let penaltyColour = 0xeac2c0
    
//    static let eightColour = Color(0xeae0b6)
//    static let twelveColour = Color(0xead4b6)
//    static let penaltyColour = Color(0xeac2c0)
}

func getGradient(gradientArray: [[Color]], gradientSelected: Int?) -> LinearGradient {
    if let gradientSelected = gradientSelected {
        return LinearGradient(gradient: Gradient(colors: gradientArray[gradientSelected]), startPoint: .bottomTrailing, endPoint: .topLeading)
    } else {
        return LinearGradient(gradient: Gradient(colors: gradientArray[6]), startPoint: .bottomTrailing, endPoint: .topLeading)
    }
}

func getGradientColours(gradientArray: [[Color]], gradientSelected: Int?) -> [Color] {
    if let gradientSelected = gradientSelected {
        return gradientArray[gradientSelected]
    } else {
        return gradientArray[6]
    }
}

class CustomGradientColours {
    static let gradientColours: [[Color]] = [
        [Color(0x0093c1), Color(0x05537a)], // light blue - dark blue
        [Color(0x52c8cd), Color(0x007caa)], // aqua - light blue
        [Color(0xe6e29a), Color(0x3ec4d0)], // pale yellow/white ish - aqua
        [Color(0xffd325), Color(0x94d7be)], // yellow - green
        [Color(0xff9e45), Color(0xffd63c)], // pale orange-yellow
        
        [Color(0xfc7018), Color(0xffc337)], // darker orange - yellow
        [Color(0xfb5b5c), Color(0xff9528)], // pink-orange
        [Color(0xd35082), Color(0xf77d4f)], // magenta-orange
        [Color(0x8548ba), Color(0xd95378)], // purple-pink
        [Color(0x3f248f), Color(0x702f86)], // dark blue-purple
    ]
}
