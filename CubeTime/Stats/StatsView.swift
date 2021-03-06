import SwiftUI
import CoreData

struct StatsBlock<Content: View>: View {
    @Environment(\.colorScheme) var colourScheme
    @AppStorage(asKeys.gradientSelected.rawValue) private var gradientSelected: Int = 6
    
    let dataView: Content
    let title: String
    let blockHeight: CGFloat?
    let bigBlock: Bool
    let coloured: Bool
    
    
    init(_ title: String, _ blockHeight: CGFloat?, _ bigBlock: Bool, _ coloured: Bool, @ViewBuilder _ dataView: () -> Content) {
        self.dataView = dataView()
        self.title = title
        self.bigBlock = bigBlock
        self.coloured = coloured
        self.blockHeight = blockHeight
    }
    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    HStack {
                        Text(title)
                            .font(.footnote.weight(.medium))
                            .foregroundColor(Color(uiColor: title == "CURRENT STATS" ? (colourScheme == .light ? .black : .white) : (coloured ? (colourScheme == .light ? .systemGray5 : .white) : .systemGray)))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 9)
                .padding(.leading, 12)
                
                dataView
            }
        }
        .frame(height: blockHeight)
        .if(coloured) { view in
            view.background(getGradient(gradientArray: CustomGradientColours.gradientColours, gradientSelected: gradientSelected)                                        .clipShape(RoundedRectangle(cornerRadius:16)))
        }
        .if(!coloured) { view in
            view.background(Color(uiColor: title == "CURRENT STATS" ? .systemGray5 : (colourScheme == .light ? .white : .systemGray6)).clipShape(RoundedRectangle(cornerRadius:16)))
        }
        .if(bigBlock) { view in
            view.padding(.horizontal)
        }
    }
}

struct StatsBlockText: View {
    @Environment(\.colorScheme) var colourScheme
    @AppStorage(asKeys.gradientSelected.rawValue) private var gradientSelected: Int = 6
    
    let displayText: String
    let colouredText: Bool
    let colouredBlock: Bool
    let displayDetail: Bool
    let nilCondition: Bool
    
    init(_ displayText: String, _ colouredText: Bool, _ colouredBlock: Bool, _ displayDetail: Bool, _ nilCondition: Bool) {
        self.displayText = displayText
        self.colouredText = colouredText
        self.colouredBlock = colouredBlock
        self.displayDetail = displayDetail
        self.nilCondition = nilCondition
    }
    
    var body: some View {
        VStack {
            if !displayDetail {
                Spacer()
            }
            
            HStack {
                if nilCondition {
                    Text(displayText)
                        .font(.largeTitle.weight(.bold))
                        .frame(minWidth: 0, maxWidth: UIScreen.screenWidth/2 - 42, alignment: .leading)
                        .modifier(DynamicText())
                        .padding(.bottom, 2)
                    
                        .if(!colouredText) { view in
                            view.foregroundColor(Color(uiColor: colouredBlock ? .white : (colourScheme == .light ? .black : .white)))
                        }
                        .if(colouredText) { view in
                            view.gradientForeground(gradientSelected: gradientSelected)
                        }
                    
                        
                    
                } else {
                    VStack {
                        Text("-")
                            .font(.title.weight(.medium))
                            .foregroundColor(Color(uiColor: .systemGray5))
                            .padding(.top, 20)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .offset(y: displayDetail ? 30 : 0)
            
            if displayDetail {
                Spacer()
            }
            
        }
        .padding(.bottom, 4)
        .padding(.leading, 12)
    }
}

struct StatsBlockDetailText: View {
    @Environment(\.colorScheme) var colourScheme
    let calculatedAverage: CalculatedAverage
    let colouredBlock: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                ForEach(calculatedAverage.accountedSolves!, id: \.self) { solve in
                    let discarded = calculatedAverage.trimmedSolves!.contains(solve)
                    let time = formatSolveTime(secs: solve.time, penType: PenTypes(rawValue: solve.penalty)!)
                    Text(discarded ? "("+time+")" : time)
                        .font(.body)
                        .foregroundColor(discarded ? Color(uiColor: colouredBlock ? .systemGray5 : .systemGray) : (colouredBlock ? .white : (colourScheme == .light ? .black : .white)))
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 2)
                }
            }
            Spacer()
        }
        .padding(.bottom, 9)
        .padding(.leading, 12)
    }
}

struct StatsBlockSmallText: View {
    @Environment(\.colorScheme) var colourScheme
    @ScaledMetric var spacing: CGFloat = -6
    
    var titles: [String]
    var data: [CalculatedAverage?]
    var checkDNF: Bool
    @Binding var presentedAvg: CalculatedAverage?
    
    init(_ titles: [String], _ data: [CalculatedAverage?], _ presentedAvg: Binding<CalculatedAverage?>, _ checkDNF: Bool) {
        self.titles = titles
        self.data = data
        self._presentedAvg = presentedAvg
        self.checkDNF = checkDNF
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(zip(titles.indices, titles)), id: \.0) { index, title in
                HStack {
                    VStack (alignment: .leading, spacing: spacing) {
                        Text(title)
                            .font(.footnote.weight(.medium))
                            .foregroundColor(Color(uiColor: .systemGray))
                        
                        if let datum = data[index] {
                            Text(formatSolveTime(secs: datum.average ?? 0, penType: datum.totalPen))
                                .font(.title2.weight(.bold))
                                .foregroundColor(Color(uiColor: colourScheme == .light ? .black : .white))
                                .modifier(DynamicText())
                        } else {
                            Text("-")
                                .font(.title3.weight(.medium))
                                .foregroundColor(Color(uiColor:.systemGray2))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.leading, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    if data[index] != nil && (!checkDNF || (data[index]?.totalPen != .dnf)) {
                        presentedAvg = data[index]
                    }
                }
            }
        }
        .padding(.top, 12)
    }
}

struct StatsDivider: View {
    @Environment(\.colorScheme) var colourScheme

    var body: some View {
        Divider()
            .frame(width: UIScreen.screenWidth/2)
            .background(Color(uiColor: colourScheme == .light ? .systemGray5 : .systemGray))
    }
}

struct StatsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    @AppStorage(asKeys.gradientSelected.rawValue) private var gradientSelected: Int = 6
    
    // Accessibility Scaling
    @ScaledMetric var blockHeightSmall = 75
    @ScaledMetric var blockHeightMedium = 130
    @ScaledMetric var blockHeightLarge = 160
    @ScaledMetric var blockHeightExtraLarge = 215
    
    @ScaledMetric var blockHeightReachedTargets = 50
    @ScaledMetric var offsetReachedTargets = 30
    
    
    @Binding var currentSession: Sessions
    
    @State var isShowingStatsView: Bool = false
    @State var presentedAvg: CalculatedAverage? = nil
    @State var showBestSinglePopup = false
    
    let stats: Stats
    
    // best averages
    let bestAo5: CalculatedAverage?
    let bestAo12: CalculatedAverage?
    let bestAo100: CalculatedAverage?
    
    // current averages
    let currentAo5: CalculatedAverage?
    let currentAo12: CalculatedAverage?
    let currentAo100: CalculatedAverage?
    
    // other block calculations
    let bestSingle: Solves?
    let sessionMean: Double?
    
    // raw values for graphs
    let timesByDateNoDNFs: [Double]
    let timesBySpeedNoDNFs: [Double]
    
    
    // comp sim stats
    let compSimCount: Int
    let reachedTargets: Int
    
    let allCompsimAveragesByDate: [Double] // has no dnfs!!
    let allCompsimAveragesByTime: [Double]
    
    let bestCompsimAverage: CalculatedAverage?
    let currentCompsimAverage: CalculatedAverage?
    
    let currentMeanOfTen: Double?
    let bestMeanOfTen: Double?
    
    let phases: [Double]?
   
    init(currentSession: Binding<Sessions>, managedObjectContext: NSManagedObjectContext) {
        self._currentSession = currentSession
        stats = Stats(currentSession: currentSession.wrappedValue)
        
        
        self.bestAo5 = stats.getBestMovingAverageOf(5)
        self.bestAo12 = stats.getBestMovingAverageOf(12)
        self.bestAo100 = stats.getBestMovingAverageOf(100)
        
        self.currentAo5 = stats.getCurrentAverageOf(5)
        self.currentAo12 = stats.getCurrentAverageOf(12)
        self.currentAo100 = stats.getCurrentAverageOf(100)
        
        
        self.bestSingle = stats.getMin()
        self.sessionMean = stats.getSessionMean()
        
        // raw values
        self.timesByDateNoDNFs = stats.solvesNoDNFsbyDate.map { timeWithPlusTwoForSolve($0) }
        self.timesBySpeedNoDNFs = stats.solvesNoDNFs.map { timeWithPlusTwoForSolve($0) }
        
        
        // comp sim
        self.compSimCount = stats.getNumberOfAverages()
        self.reachedTargets = stats.getReachedTargets()
       
        self.allCompsimAveragesByDate = stats.getBestCompsimAverageAndArrayOfCompsimAverages().1.map { $0.average! }
        self.allCompsimAveragesByTime = self.allCompsimAveragesByDate.sorted(by: <)
        
        self.currentCompsimAverage = stats.getCurrentCompsimAverage()
        self.bestCompsimAverage = stats.getBestCompsimAverageAndArrayOfCompsimAverages().0
        
        self.currentMeanOfTen = stats.getCurrentMeanOfTen()
        self.bestMeanOfTen = stats.getBestMeanOfTen()
        
        self.phases = stats.getAveragePhases()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack (spacing: 0) {
                        
                        #if DEBUG
                        Button {
                            for _ in 0..<1000 {
                                let solveItem: Solves!

                                solveItem = Solves(context: managedObjectContext)
                                solveItem.date = Date()
                                solveItem.session = currentSession
                                solveItem.scramble = "R U R' F' D D' D F B B "
                                solveItem.scramble_type = 1
                                solveItem.scramble_subtype = 0
                                solveItem.time = Double.random(in: 6..<11)
                                
                                do {
                                    try managedObjectContext.save()
                                } catch {
                                    if let error = error as NSError? {
                                        fatalError("Unresolved error \(error), \(error.userInfo)")
                                    }
                                }
                            }
                        } label: {
                            Text("sdfsdf")
                        }
                        #endif
                        
                        
                        SessionBar(name: currentSession.name!, session: currentSession)
                            .padding(.top, -6)
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        let compsim: Bool = SessionTypes(rawValue: currentSession.session_type)! == .compsim
                        
                        /// everything
                        VStack(spacing: 10) {
                            if !compsim {
                                HStack(spacing: 10) {
                                    StatsBlock("CURRENT STATS", blockHeightLarge, false, false) {
                                        StatsBlockSmallText(["AO5", "AO12", "AO100"], [currentAo5, currentAo12, currentAo100], $presentedAvg, false)
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    
                                    VStack(spacing: 10) {
                                        StatsBlock("SOLVE COUNT", blockHeightSmall, false, false) {
                                            StatsBlockText("\(stats.getNumberOfSolves())", false, false, false, true)
                                        }
                                        
                                        StatsBlock("SESSION MEAN", blockHeightSmall, false, false) {
                                            if sessionMean != nil {
                                                StatsBlockText(formatSolveTime(secs: sessionMean!), false, false, false, true)
                                            } else {
                                                StatsBlockText("", false, false, false, false)
                                            }
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .padding(.horizontal)
                                
                                StatsDivider()
                                
                                HStack(spacing: 10) {
                                    VStack (spacing: 10) {
                                        StatsBlock("BEST SINGLE", blockHeightSmall, false, true) {
                                            if bestSingle != nil {
                                                StatsBlockText(formatSolveTime(secs: bestSingle!.time, penType: PenTypes(rawValue: bestSingle!.penalty)!), false, true, false, true)
                                            } else {
                                                StatsBlockText("", false, false, false, false)
                                            }
                                        }
                                        .onTapGesture {
                                            if bestSingle != nil { showBestSinglePopup = true }
                                        }
                                        
                                        StatsBlock("BEST STATS", blockHeightMedium, false, false) {
                                            StatsBlockSmallText(["AO12", "AO100"], [bestAo12, bestAo100], $presentedAvg, true)
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    
                                    StatsBlock("BEST AO5", blockHeightExtraLarge, false, false) {
                                        if bestAo5 != nil {
                                            StatsBlockText(formatSolveTime(secs: bestAo5?.average ?? 0, penType: bestAo5?.totalPen), true, false, true, true)
                                            
                                            StatsBlockDetailText(calculatedAverage: bestAo5!, colouredBlock: false)
                                        } else {
                                            StatsBlockText("", false, false, false, false)
                                        }
                                    }
                                    .onTapGesture {
                                        if bestAo5 != nil && bestAo5?.totalPen != .dnf {
                                            presentedAvg = bestAo5
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .padding(.horizontal)
                                
                                StatsDivider()
                                
                                if SessionTypes(rawValue: currentSession.session_type)! == .multiphase {
                                    StatsBlock("AVERAGE PHASES", timesBySpeedNoDNFs.count == 0 ? 150 : nil, true, false) {
                                        
                                        if timesByDateNoDNFs.count > 0 {
                                            AveragePhases(phaseTimes: phases!)
                                                .padding(.top, 20)
                                        } else {
                                            Text("not enough solves to\ndisplay graph")
                                                .font(.system(size: 17, weight: .medium, design: .monospaced))
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(Color(uiColor: .systemGray))
                                        }
                                    }
                                    
                                    StatsDivider()
                                }
                            } else {
                                HStack(spacing: 10) {
                                    VStack(spacing: 10) {
                                        StatsBlock("CURRENT AVG", blockHeightExtraLarge, false, false) {
                                            if currentCompsimAverage != nil {
                                                StatsBlockText(formatSolveTime(secs: currentCompsimAverage?.average ?? 0, penType: currentCompsimAverage?.totalPen), false, false, true, true)
                                                    
                                                StatsBlockDetailText(calculatedAverage: currentCompsimAverage!, colouredBlock: false)
                                            } else {
                                                StatsBlockText("", false, false, false, false)
                                            }
                                        }
                                        .onTapGesture {
                                            if currentCompsimAverage != nil && currentCompsimAverage?.totalPen != .dnf {
                                                presentedAvg = currentCompsimAverage
                                            }
                                        }
                                        
                                        StatsBlock("AVERAGES", blockHeightSmall, false, false) {
                                            StatsBlockText("\(compSimCount)", false, false, false, true)
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    
                                    VStack(spacing: 10) {
                                        StatsBlock("BEST SINGLE", blockHeightSmall, false, false) {
                                            if bestSingle != nil {
                                                StatsBlockText(formatSolveTime(secs: bestSingle!.time), true, false, false, true)
                                            } else {
                                                StatsBlockText("", false, false, false, false)
                                            }
                                        }
                                        .onTapGesture {
                                            if bestSingle != nil {
                                                showBestSinglePopup = true
                                            }
                                        }
                                        
                                        StatsBlock("BEST AVG", blockHeightExtraLarge, false, true) {
                                            if bestCompsimAverage != nil {
                                                StatsBlockText(formatSolveTime(secs: bestCompsimAverage?.average ?? 0, penType: bestCompsimAverage?.totalPen), false, true, true, true)
                                                
                                                StatsBlockDetailText(calculatedAverage: bestCompsimAverage!, colouredBlock: true)

                                            } else {
                                                StatsBlockText("", false, false, false, false)
                                            }
                                        }
                                        .onTapGesture {
                                            if bestCompsimAverage?.totalPen != .dnf {
                                                presentedAvg = bestCompsimAverage
                                            }
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .padding(.horizontal)
                                
                                StatsDivider()
                                
                                HStack(spacing: 10) {
                                    StatsBlock("TARGET", blockHeightSmall, false, false) {
                                        StatsBlockText(formatSolveTime(secs: (currentSession as! CompSimSession).target, dp: 2), false, false, false, true)
                                    }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                    
                                    StatsBlock("REACHED", blockHeightSmall, false, false) {
                                        StatsBlockText("\(reachedTargets)/\(compSimCount)", false, false, false, (bestSingle != nil))
                                    }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .padding(.horizontal)
                                
                                
                                StatsBlock("REACHED TARGETS", compSimCount == 0 ? 150 : blockHeightReachedTargets, true, false) {
                                    if compSimCount != 0 {
                                        ReachedTargets(Float(reachedTargets)/Float(compSimCount))
                                            .padding(.horizontal, 12)
                                            .offset(y: offsetReachedTargets)
                                    } else {
                                        Text("not enough solves to\ndisplay graph")
                                            .font(.system(size: 17, weight: .medium, design: .monospaced))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(uiColor: .systemGray))
                                    }
                                }
                                
                                StatsDivider()
                                
                                HStack(spacing: 10) {
                                    StatsBlock("CURRENT MO10 AO5", blockHeightSmall, false, false) {
                                        if currentMeanOfTen != nil {
                                            StatsBlockText(formatSolveTime(secs: currentMeanOfTen!, penType: ((currentMeanOfTen == -1) ? .dnf : PenTypes.none)), false, false, false, true)
                                        } else {
                                            StatsBlockText("", false, false, false, false)
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    
                                    StatsBlock("BEST MO10 AO5", blockHeightSmall, false, false) {
                                        if bestMeanOfTen != nil {
                                            StatsBlockText(formatSolveTime(secs: bestMeanOfTen!, penType: ((bestMeanOfTen == -1) ? .dnf : PenTypes.none)), false, false, false, true)
                                        } else {
                                            StatsBlockText("", false, false, false, false)
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .padding(.horizontal)
                                
                                StatsDivider()
                            }
                            
                            
                            let timeTrendData = (compsim ? allCompsimAveragesByDate : timesByDateNoDNFs)
                            let timeDistributionData = (compsim ? allCompsimAveragesByTime : timesBySpeedNoDNFs)
                            
                            StatsBlock("TIME TREND", (timeTrendData.count < 2 ? 150 : 310), true, false) {
                                
                                TimeTrend(data: timeTrendData, title: nil, style: ChartStyle(.white, .black, Color.black.opacity(0.24)))
                                    .frame(width: UIScreen.screenWidth - (2 * 16) - (2 * 12))
                                    .padding(.horizontal, 12)
                                    .offset(y: -4)
                                    .drawingGroup()
                            }
                            
                            StatsBlock("TIME DISTRIBUTION", (timeDistributionData.count < 4 ? 150 : 310), true, false) {
                                TimeDistribution(currentSession: $currentSession, solves: timeDistributionData)
                                    .drawingGroup()
                                    .frame(height: timeDistributionData.count < 4 ? 150 : 300)
                            }
                        }
                    }
                }
                .navigationTitle("Your Solves")
                .safeAreaInset(edge: .bottom, spacing: 0) {RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.clear).frame(height: 50).padding(.top).padding(.bottom, SetValues.hasBottomBar ? 0 : nil)}
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $presentedAvg) { item in
            StatsDetail(solves: item, session: currentSession)
        }
        .sheet(isPresented: $showBestSinglePopup) {
            TimeDetail(solve: bestSingle!, currentSolve: nil, timeListManager: nil) // TODO make delete work from here
            // maybe pass stats object and make it remove min
        }
    }
}
