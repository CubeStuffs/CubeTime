import SwiftUI
import SVGView
import SwiftfulLoadingIndicators

enum TimerTool {
    case drawScramble
    case statsCompsim
    case statsStandard
}

struct BottomTools: View {
    @Environment(\.horizontalSizeClass) var hSizeClass
    @EnvironmentObject var stopwatchManager: StopwatchManager
    @Preference(\.showScramble) private var showScramble
    @Preference(\.showStats) private var showStats
    
    let timerSize: CGSize
    @Binding var scrambleSheetStr: SheetStrWrapper?
    @Binding var presentedAvg: CalculatedAverage?
    
    
    var body: some View {
        HStack(alignment: .bottom) {
            if showScramble {
                BottomToolContainer {
                    TimerDrawScramble(scrambleSheetStr: $scrambleSheetStr)
                }
            }
            
            if showScramble && showStats {
                Spacer()
            }
            
            if showStats {
                BottomToolContainer {
                    if stopwatchManager.currentSession.session_type == SessionTypes.compsim.rawValue {
                        TimerStatsCompSim()
                    } else {
                        if (UIDevice.deviceIsPad && hSizeClass == .regular) {
                            TimerStatsPad()
                        } else {
                            TimerStatsStandard(presentedAvg: $presentedAvg)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.bottom, (UIDevice.deviceIsPad && hSizeClass == .regular) ? 50 - 18 : 50 + 8)
        // 18 = height of drag part
        // 8 = top padding for phone
        .padding(.horizontal)
    }
}

struct BottomToolBG: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color("overlay0"))
    }
}


struct BottomToolContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("overlay0"))
            
            content
        }
        .frame(maxWidth: 170)
        .frame(height: 120)
    }
}

struct TimerDrawScramble: View {
    @EnvironmentObject var scrambleController: ScrambleController
    @Binding var scrambleSheetStr: SheetStrWrapper?
    
    var body: some View {
        GeometryReader { geo in
            if let svg = scrambleController.scrambleSVG {
                if let scr = scrambleController.scrambleStr {
                    SVGView(string: svg)
                        .padding(2)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(width: geo.size.width, height: geo.size.height) // For some reason above doesnt work
//                        .transition(.asymmetric(insertion: .opacity.animation(.easeIn(duration: 0.10)), removal: .identity))
                        .aspectRatio(contentMode: .fit)
                        .onTapGesture {
                            scrambleSheetStr = SheetStrWrapper(str: scr)
                        }
                }
            } else {
                LoadingIndicator(animation: .circleRunner, color: Color("accent"), size: .small, speed: .fast)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}


struct TimerStatRaw: View {
    let name: String
    let value: String?
    let placeholderText: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
            
            if let value = value {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .modifier(DynamicText())
            } else {
                Text(placeholderText)
                    .font(.system(size: 24, weight: .medium, design: .default))
                    .foregroundColor(Color("grey"))
            }
            
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct TimerStat: View {
    let name: String
    let average: CalculatedAverage?
    let value: String?
    let placeholderText: String
    let hasIndividualGesture: Bool
    @Binding var presentedAvg: CalculatedAverage?

    init(name: String, average: CalculatedAverage?, placeholderText: String = "-", presentedAvg: Binding<CalculatedAverage?>, hasIndividualGesture: Bool=true) {
        self.name = name
        self.average = average
        self.placeholderText = placeholderText
        self.hasIndividualGesture = hasIndividualGesture
        self._presentedAvg = presentedAvg
        if let average = average {
            self.value = formatSolveTime(secs: average.average!, penType: average.totalPen)
        } else {
            self.value = nil
        }
    }

    var body: some View {
        if (hasIndividualGesture) {
            TimerStatRaw(name: name, value: value, placeholderText: placeholderText)
                .onTapGesture {
                    if average != nil {
                        presentedAvg = average
                    }
                }
        } else {
            TimerStatRaw(name: name, value: value, placeholderText: placeholderText)
        }
    }
}

struct TimerStatsStandard: View {
    @EnvironmentObject var stopwatchManager: StopwatchManager
    @Binding var presentedAvg: CalculatedAverage?
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                TimerStat(name: "AO5", average: stopwatchManager.currentAo5, presentedAvg: $presentedAvg)
                TimerStat(name: "AO12", average: stopwatchManager.currentAo12, presentedAvg: $presentedAvg)
            }
            
            ThemedDivider()
                .padding(.horizontal, 24)
            
            
            HStack(spacing: 0) {
                TimerStat(name: "AO100", average: stopwatchManager.currentAo5, presentedAvg: $presentedAvg)
                TimerStatRaw(name: "MEAN", value: stopwatchManager.sessionMean == nil ? nil : formatSolveTime(secs: stopwatchManager.sessionMean!), placeholderText: "-")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TimerStatsPad: View {
    @EnvironmentObject var stopwatchManager: StopwatchManager
    @State private var showStats: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                TimerStat(name: "AO5", average: stopwatchManager.currentAo5, presentedAvg: .constant(nil), hasIndividualGesture: false)
                TimerStat(name: "AO12", average: stopwatchManager.currentAo12, presentedAvg: .constant(nil), hasIndividualGesture: false)
            }
            
            ThemedDivider()
                .padding(.horizontal, 24)
            
            
            HStack(spacing: 0) {
                TimerStat(name: "AO100", average: stopwatchManager.currentAo5, presentedAvg: .constant(nil), hasIndividualGesture: false)
                TimerStatRaw(name: "MEAN", value: stopwatchManager.sessionMean == nil ? nil : formatSolveTime(secs: stopwatchManager.sessionMean!), placeholderText: "-")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            self.showStats = true
        }
        .sheet(isPresented: self.$showStats) {
            StatsView()
        }
    }
}


struct TimerStatsCompSim: View {
    @EnvironmentObject var stopwatchManager: StopwatchManager

    
    var body: some View {
        let timeNeededText: String? = {
            if let timeNeededForTarget = stopwatchManager.timeNeededForTarget {
                switch timeNeededForTarget {
                case .notPossible:
                    return "Not Possible"
                case .guaranteed:
                    return "Guaranteed"
                case .value(let double):
                    return formatSolveTime(secs: double)
                }
            }
            return nil
        }()
    
        VStack(spacing: 6) {
            HStack {
                TimerStatRaw(name: "BPA", value: stopwatchManager.bpa == nil ? nil : formatSolveTime(secs: stopwatchManager.bpa!), placeholderText: "...")
                TimerStatRaw(name: "WPA", value: stopwatchManager.wpa == nil ? nil : formatSolveTime(secs: stopwatchManager.wpa!), placeholderText: "...")
            }
            
            ThemedDivider()
                .padding(.horizontal, 24)
            
            TimerStatRaw(name: "TO REACH TARGET", value: stopwatchManager.wpa == nil ? nil : formatSolveTime(secs: stopwatchManager.wpa!), placeholderText: "...")
        }
    }
}
