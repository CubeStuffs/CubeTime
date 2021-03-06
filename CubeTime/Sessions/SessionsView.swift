import SwiftUI
import CoreData
import Combine


/// **viewmodifiers**
struct NewStandardSessionViewBlocks: ViewModifier {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    func body(content: Content) -> some View {
        content
            .background(colorScheme == .light ? Color.white : Color(uiColor: .systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
    }
}

struct ContextMenuButton: View {
    var delay: Bool
    var action: () -> Void
    var title: String
    var systemImage: String? = nil
    var disableButton: Bool? = nil
    
    init(delay: Bool, action: @escaping () -> Void, title: String, systemImage: String?, disableButton: Bool?) {
        self.delay = delay
        self.action = action
        self.title = title
        self.systemImage = systemImage
        self.disableButton = disableButton
    }
    
    var body: some View {
        Button(role: title == "Delete Session" ? .destructive : nil, action: delayedAction) {
            HStack {
                Text(title)
                if image != nil {
                    Image(uiImage: image!)
                }
            }
        }.disabled(disableButton ?? false)
    }
    
    private var image: UIImage? {
        if let systemName = systemImage {
            let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .body), scale: .medium)
            
            return UIImage(systemName: systemName, withConfiguration: config)
        } else {
            return nil
        }
    }
    private func delayedAction() {
        DispatchQueue.main.asyncAfter(deadline: .now() + (delay ? 0.9 : 0)) {
            self.action()
        }
    }
}

/// **Customise Sessions **
struct CustomiseStandardSessionView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var stopWatchManager: StopWatchManager
    
    let sessionItem: Sessions
    
    @State private var name: String
    @State private var targetStr: String
    @State private var phaseCount: Int
    
    @State var pinnedSession: Bool
    
    @ScaledMetric(relativeTo: .body) var frameHeight: CGFloat = 45
    @ScaledMetric(relativeTo: .title2) var bigFrameHeight: CGFloat = 220
    
    
    
    let sessionEventTypeColumns = [GridItem(.adaptive(minimum: 40))]
    
    
    @State private var sessionEventType: Int32
    
    
    init(sessionItem: Sessions) {
        self.sessionItem = sessionItem
        
        self._name = State(initialValue: sessionItem.name ?? "")
        self._pinnedSession = State(initialValue: sessionItem.pinned)
        self._targetStr = State(initialValue: filteredStrFromTime((sessionItem as? CompSimSession)?.target))
        self._phaseCount = State(initialValue: Int((sessionItem as? MultiphaseSession)?.phase_count ?? 0))
        
        self._sessionEventType = State(initialValue: sessionItem.scramble_type)
    }
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .center, spacing: 0) {
                            Image(puzzle_types[Int(sessionEventType)].name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.top)
                                .padding(.bottom)
                                .shadow(color: .black.opacity(0.24), radius: 12, x: 0, y: 4)
                            
                            
                            TextField("Session Name", text: $name)
                                .padding(12)
                                .font(.title2.weight(.semibold))
                                .multilineTextAlignment(TextAlignment.center)
                                .background(Color(uiColor: .systemGray5))
                                .cornerRadius(10)
                                .padding([.horizontal, .bottom])
                        }
                        .frame(height: bigFrameHeight)
                        .modifier(NewStandardSessionViewBlocks())
                        
                        if sessionItem.session_type == SessionTypes.compsim.rawValue {
                            VStack (spacing: 0) {
                                HStack {
                                    Text("Target")
                                        .font(.body.weight(.medium))
                                    
                                    Spacer()
                                    
                                    TextField("0.00", text: $targetStr)
                                        .multilineTextAlignment(.trailing)
                                        .modifier(TimeMaskTextField(text: $targetStr))
                                }
                                .padding()
                            }
                            .frame(height: frameHeight)
                            .modifier(NewStandardSessionViewBlocks())
                        }
                        
                        
                        /// TEMPORARITLY REMOVED MODIFYING PHASES IN STANDARD MULTIPHASE SESSION
                        
                        
                        /*
                        if sessionItem.session_type == SessionTypes.multiphase.rawValue {
                            VStack (spacing: 0) {
                                HStack(spacing: 0) {
                                    Text("Phases: ")
                                        .font(.body.weight(.medium))
                                    Text("\(phaseCount)")
                                    
                                    Spacer()
                                    
                                    Stepper("", value: $phaseCount, in: 2...8)
                                    
                                }
                                .padding()
                            }
                            .frame(height: frameHeight)
                            .modifier(NewStandardSessionViewBlocks())
                        }
                         */
                        
                        if sessionItem.session_type == SessionTypes.playground.rawValue {
                            VStack (spacing: 0) {
                                LazyVGrid(columns: sessionEventTypeColumns, spacing: 0) {
                                    ForEach(Array(zip(puzzle_types.indices, puzzle_types)), id: \.0) { index, element in
                                        Button {
                                            sessionEventType = Int32(index)
                                        } label: {
                                            ZStack {
                                                Image("circular-" + element.name)
                                                
                                                Circle()
                                                    .strokeBorder(Color(uiColor: .systemGray3), lineWidth: (index == sessionEventType) ? 3 : 0)
                                                    .frame(width: 54, height: 54)
                                                    .offset(x: -0.2)
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                            .frame(height: 180)
                            .modifier(NewStandardSessionViewBlocks())
                        }
                        
                        
                        VStack (spacing: 0) {
                            HStack {
                                Toggle(isOn: $pinnedSession) {
                                    Text("Pin Session?")
                                        .font(.body.weight(.medium))
                                }
                                .tint(.yellow)
                            }
                            .padding()
                        }
                        .frame(height: frameHeight)
                        .modifier(NewStandardSessionViewBlocks())
                    }
                }
                .ignoresSafeArea(.keyboard)
                .navigationBarTitle("Customise Session", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            sessionItem.name = name
                            sessionItem.pinned = pinnedSession
                            
                            if sessionItem.session_type == SessionTypes.compsim.rawValue {
                                (sessionItem as! CompSimSession).target = timeFromStr(targetStr)!
                            }
                            
                            if sessionItem.session_type == SessionTypes.multiphase.rawValue {
                                (sessionItem as! MultiphaseSession).phase_count = Int16(phaseCount)
                            }
                            
                            if sessionItem.session_type == SessionTypes.playground.rawValue {
                                sessionItem.scramble_type = Int32(sessionEventType)
                                stopWatchManager.rescramble()
                            }
                            
                            try! managedObjectContext.save()
                            
                            dismiss()
                        } label: {
                            Text("Done")
                        }
                        .disabled(self.name.isEmpty || (sessionItem.session_type == SessionTypes.compsim.rawValue && targetStr.isEmpty))
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}


/// **New sessions**
struct NewSessionPopUpView: View {
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colourScheme
    
    @State private var showNewStandardSessionView = false
    @State private var showNewAlgTrainerView = false
    @State private var showNewMultiphaseView = false
    @State private var showNewPlaygroundView = false
    @State private var showNewCompsimView = false
    
    @ScaledMetric(relativeTo: .body) var frameHeight: CGFloat = 45
    @ScaledMetric(relativeTo: .title2) var bigFrameHeight: CGFloat = 220

        
    @State private var testBool = false
    
    @Binding var currentSession: Sessions
    @Binding var showNewSessionPopUp: Bool
    
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    VStack(alignment: .center) {
                        Text("Add New Session")
                            .font(.system(size: 34, weight: .bold, design: .default))
                            .padding(.bottom, 8)
                            .padding(.top, UIScreen.screenHeight/12)
                    }
                    
                    
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Group {
                            Text("Normal Sessions")
                                .font(.system(size: 22, weight: .bold, design: .default))
                                .padding(.leading, 20)
                                .padding(.bottom, 8)
                            
                            HStack {
                                Image(systemName: "timer.square")
                                    .font(.system(size: 26, weight: .regular))
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                    .padding(.leading, 8)
                                    .padding(.trailing, 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                Text("Standard Session")
                                    .font(.body)
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                //.padding(10)
                                Spacer()
                            }
                            
                            .background(Color(uiColor: colourScheme == .light ? .systemGray6 : .black))
                            .onTapGesture {
                                showNewStandardSessionView = true
                            }
                            .cornerRadius(10, corners: .topRight)
                            .cornerRadius(10, corners: .topLeft)
                            .padding(.leading)
                            .padding(.trailing)
                            
                            
                            ZStack {
                                Rectangle()
                                    .fill(Color(uiColor: colourScheme == .dark ? .black : .systemGray6))
                                    .frame(height: 1)
                                    .padding(.leading)
                                    .padding(.trailing)
                                
                                Divider()
                                    .padding(.leading, 64)
                                    .padding(.trailing)
                            }
                            
                            
                            /*
                            HStack {
                                Image(systemName: "command.square")
                                    .font(.system(size: 26, weight: .regular))
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                //                                    .symbolRenderingMode(.hierarchical)
                                    .padding(.leading, 8)
                                    .padding(.trailing, 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                Text("Algorithm Trainer") // wip
                                    .font(.body)
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                
                                Spacer()
                            }
                            .background(Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                                            .clipShape(Rectangle()))
                            .onTapGesture {
                                showNewAlgTrainerView = true
                            }
                            .padding(.leading)
                            .padding(.trailing)
                            
                            
                            ZStack {
                                Rectangle()
                                    .fill(Color(uiColor: colourScheme == .dark ? .black : .systemGray6))
                                    .frame(height: 1)
                                    .padding(.leading)
                                    .padding(.trailing)
                                Divider()
                                    .padding(.leading, 64)
                                    .padding(.trailing)
                            }
                             */
                            
                            /// alg trainer commented out for now
                        }
                        
                        
                        Group {
                            HStack {
                                Image(systemName: "square.stack")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                //                                .symbolRenderingMode(.hierarchical)
                                    .padding(.leading, 10)
                                    .padding(.trailing, 6)
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                Text("Multiphase") // wip
                                    .font(.body)
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                
                                Spacer()
                            }
                            .background(Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                                            .clipShape(Rectangle()))
                            .onTapGesture {
                                showNewMultiphaseView = true
                            }
                            .padding(.leading)
                            .padding(.trailing)
                            
                            
                            ZStack {
                                Rectangle()
                                    .fill(Color(uiColor: colourScheme == .dark ? .black : .systemGray6))
                                    .frame(height: 1)
                                    .padding(.leading)
                                    .padding(.trailing)
                                
                                Divider()
                                    .padding(.leading, 64)
                                    .padding(.trailing)
                            }
                            
                            
                            
                            
                            
                            HStack {
                                Image(systemName: "square.on.square")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                //                                .symbolRenderingMode(.hierarchical)
                                    .padding(.leading, 8)
                                    .padding(.trailing, 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                Text("Playground") // wip
                                    .font(.body)
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                
                                Spacer()
                            }
                            .background(Color(uiColor: colourScheme == .light ? .systemGray6 : .black))
                            .onTapGesture {
                                showNewPlaygroundView = true
                            }
                            .cornerRadius(10, corners: .bottomRight)
                            .cornerRadius(10, corners: .bottomLeft)
                            .padding(.horizontal)
                            
                            
                            
                            
                            Text("Other Sessions")
                                .font(.system(size: 22, weight: .bold, design: .default))
                                .padding(.top, 48)
                                .padding(.leading, 20)
                                .padding(.bottom, 8)
                             
                             
                             
                            HStack {
                                Image(systemName: "globe.asia.australia")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                //                                .symbolRenderingMode(.hierarchical)
                                    .padding(.leading, 8)
                                    .padding(.trailing, 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                Text("Comp Sim") // wip
                                    .font(.body)
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                
                                Spacer()
                            }
                            .background(Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)))
                            .onTapGesture {
                                showNewCompsimView = true
                            }
                            .padding(.leading)
                            .padding(.trailing)
                        }
                        
                        
                        
                        NavigationLink("", destination: NewStandardSessionView(showNewSessionPopUp: $showNewSessionPopUp, currentSession: $currentSession, pinnedSession: false), isActive: $showNewStandardSessionView)
                        
                        /*
                        NavigationLink("", destination: NewAlgTrainerView(showNewSessionPopUp: $showNewSessionPopUp, currentSession: $currentSession, pinnedSession: false), isActive: $showNewAlgTrainerView)
                         */
                        
                        NavigationLink("", destination: NewMultiphaseView(showNewSessionPopUp: $showNewSessionPopUp, currentSession: $currentSession, pinnedSession: false), isActive: $showNewMultiphaseView)
                        
                        NavigationLink("", destination: NewPlaygroundView(showNewSessionPopUp: $showNewSessionPopUp, currentSession: $currentSession, pinnedSession: false), isActive: $showNewPlaygroundView)
                        
                        NavigationLink("", destination: NewCompsimView(showNewSessionPopUp: $showNewSessionPopUp, currentSession: $currentSession, pinnedSession: false), isActive: $showNewCompsimView)
                        
                        Spacer()
                        
                    }
                    
                    
                    
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                                    .foregroundStyle(colourScheme == .light ? .black : .white)
                                    .padding(.top)
                                    .padding(.trailing)
                            }
                        }
                        Spacer()
                    }
                )
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .accentColor(accentColour)
        }
    }
}

struct NewStandardSessionView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    @Binding var showNewSessionPopUp: Bool
    @Binding var currentSession: Sessions
    @State private var name: String = ""
    @State private var sessionEventType: Int32 = 0
    @State var pinnedSession: Bool
    
    @ScaledMetric(relativeTo: .body) var frameHeight: CGFloat = 45
    @ScaledMetric(relativeTo: .title2) var bigFrameHeight: CGFloat = 220

    
    let sessionEventTypeColumns = [GridItem(.adaptive(minimum: 40))]
    
    var body: some View {
        ZStack {
            Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                .ignoresSafeArea()
            
            ScrollView {
                VStack (spacing: 16) {
                    VStack (alignment: .center, spacing: 0) {
                        Image(puzzle_types[Int(sessionEventType)].name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .padding(.top)
                            .padding(.bottom)
                            .shadow(color: .black.opacity(0.24), radius: 12, x: 0, y: 4)
                        
                        
                        
                        TextField("Session Name", text: $name)
                            .padding(12)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(TextAlignment.center)
                            .background(Color(uiColor: .systemGray5))
                            .cornerRadius(10)
                            .padding([.horizontal, .vertical])
                    }
                    .frame(height: bigFrameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    VStack (spacing: 0) {
                        HStack {
                            Text("Session Event")
                                .font(.body.weight(.medium))
                            
                            
                            Spacer()
                            
                            Picker("", selection: $sessionEventType) {
                                ForEach(Array(puzzle_types.enumerated()), id: \.offset) {index, element in
                                    Text(element.name).tag(Int32(index))
                                        .font(.body)
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(accentColour)
                            .font(.body)
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    
                    VStack (spacing: 0) {
                        LazyVGrid(columns: sessionEventTypeColumns, spacing: 0) {
                            ForEach(Array(zip(puzzle_types.indices, puzzle_types)), id: \.0) { index, element in
                                Button {
                                    sessionEventType = Int32(index)
                                } label: {
                                    ZStack {
                                        Image("circular-" + element.name)
                                        
                                        Circle()
                                            .strokeBorder(Color(uiColor: .systemGray3), lineWidth: (index == sessionEventType) ? 3 : 0)
                                            .frame(width: 54, height: 54)
                                            .offset(x: -0.2)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(height: 180)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    
                    
                    VStack (spacing: 0) {
                        HStack {
                            Toggle(isOn: $pinnedSession) {
                                Text("Pin Session?")
                                    .font(.body.weight(.medium))
                            }
                            .tint(.yellow)
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    Spacer()
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("New Standard Session", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let sessionItem = Sessions(context: managedObjectContext)
                        sessionItem.name = name
                        sessionItem.pinned = pinnedSession
                        sessionItem.scramble_type = sessionEventType
                        try! managedObjectContext.save()
                        currentSession = sessionItem
                        showNewSessionPopUp = false
                        currentSession = sessionItem
                    } label: {
                        Text("Create")
                    }
                    .disabled(self.name.isEmpty)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct NewMultiphaseView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    @State private var name: String = ""
    @State private var sessionEventType: Int32 = 0
    @State private var phaseCount: Int = 2
    
    @Binding var showNewSessionPopUp: Bool
    @Binding var currentSession: Sessions
    
    @State var pinnedSession: Bool
    
    @ScaledMetric(relativeTo: .body) var frameHeight: CGFloat = 45
    @ScaledMetric(relativeTo: .title2) var bigFrameHeight: CGFloat = 80

    
//    init(showNewSessionPopUp: Binding<Bool>, currentSession: Binding<Bool>, pinnedSession: Bool) {
//        self.showNewSessionPopUp
//    }

    let sessionEventTypeColumns = [GridItem(.adaptive(minimum: 40))]
    
    var body: some View {
        ZStack {
            Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                .ignoresSafeArea()
            
            ScrollView {
                VStack (spacing: 16) {
                    
                    VStack (alignment: .center, spacing: 0) {
                        Image(puzzle_types[Int(sessionEventType)].name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .padding(.top)
                            .padding(.bottom)
                            .shadow(color: .black.opacity(0.24), radius: 12, x: 0, y: 4)
                        
                        
                        TextField("Session Name", text: $name)
                            .padding(12)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(TextAlignment.center)
                            .background(Color(uiColor: .systemGray5))
                            .cornerRadius(10)
                            .padding(.leading)
                            .padding(.trailing)
                            .padding(.bottom)
                        
                        Text("A multiphase session gives you the ability to breakdown your solves into sections, such as blindfolded solves or stages in a 3x3 solve.\n\nTo use, tap anywhere on the timer during a solve to record a phase lap. You can access your breakdown statistics in each time card.")
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color(uiColor: .systemGray))
                            .padding(.horizontal)
                            .padding(.bottom)
                        
                    }
                    .frame(minHeight: bigFrameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    VStack (spacing: 0) {
                        HStack(spacing: 0) {
                            Text("Phases: ")
                                .font(.body.weight(.medium))
                            Text("\(phaseCount)")
                            
                            Spacer()
                            
                            Stepper("", value: $phaseCount, in: 2...8)
                            
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    
                    VStack (spacing: 0) {
                        HStack {
                            Text("Session Event")
                                .font(.body.weight(.medium))
                            
                            
                            Spacer()
                            
                            Picker("", selection: $sessionEventType) {
                                ForEach(Array(puzzle_types.enumerated()), id: \.offset) {index, element in
                                    Text(element.name).tag(Int32(index))
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(accentColour)
                            .font(.body)
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    
                    VStack (spacing: 0) {
                        LazyVGrid(columns: sessionEventTypeColumns, spacing: 0) {
                            ForEach(Array(zip(puzzle_types.indices, puzzle_types)), id: \.0) { index, element in
                                Button {
                                    sessionEventType = Int32(index)
                                } label: {
                                    ZStack {
                                        Image("circular-" + element.name)
                                        
                                        Circle()
                                            .strokeBorder(Color(uiColor: .systemGray3), lineWidth: (index == sessionEventType) ? 3 : 0)
                                            .frame(width: 54, height: 54)
                                            .offset(x: -0.2)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(height: 180)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    
                    
                    VStack (spacing: 0) {
                        HStack {
                            Toggle(isOn: $pinnedSession) {
                                Text("Pin Session?")
                                    .font(.body.weight(.medium))
                            }
                            .tint(.yellow)
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    Spacer()
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("New Multiphase Session", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let sessionItem = MultiphaseSession(context: managedObjectContext)
                        sessionItem.name = name
                        sessionItem.pinned = pinnedSession
                        sessionItem.phase_count = Int16(phaseCount)
                        sessionItem.session_type = 2
                        
                        sessionItem.scramble_type = sessionEventType
                        try! managedObjectContext.save()
                        currentSession = sessionItem
                        showNewSessionPopUp = false
                        currentSession = sessionItem
                    } label: {
                        Text("Create")
                    }
                    .disabled(self.name.isEmpty)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct NewPlaygroundView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    @Binding var showNewSessionPopUp: Bool
    @Binding var currentSession: Sessions
    @State private var name: String = ""
    @State private var sessionEventType: Int32 = 0
    @State var pinnedSession: Bool
    
    @ScaledMetric(relativeTo: .body) var frameHeight: CGFloat = 45
    @ScaledMetric(relativeTo: .title2) var bigFrameHeight: CGFloat = 80

    
    var body: some View {
        ZStack {
            Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                .ignoresSafeArea()
            
            ScrollView {
                VStack (spacing: 16) {
                    
                    VStack (alignment: .center, spacing: 0) {
                        
                        TextField("Session Name", text: $name)
                            .padding(12)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(TextAlignment.center)
                            .background(Color(uiColor: .systemGray5))
                            .cornerRadius(10)
                            .padding()
                        
                        Text("A playground session allows you to quickly change the scramble type within a session without having to specify a scramble type for the whole session.")
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color(uiColor: .systemGray))
                            .padding([.horizontal, .bottom])
                    }
                    .frame(minHeight: bigFrameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    
                    VStack (spacing: 0) {
                        HStack {
                            Toggle(isOn: $pinnedSession) {
                                Text("Pin Session?")
                                    .font(.body.weight(.medium))
                            }
                            .tint(.yellow)
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    Spacer()
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("New Playground Session", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let sessionItem = Sessions(context: managedObjectContext)
                        sessionItem.name = name
                        sessionItem.pinned = pinnedSession
                        
                        sessionItem.session_type = 3
                        try! managedObjectContext.save()
                        currentSession = sessionItem
                        showNewSessionPopUp = false
                        currentSession = sessionItem
                        
                    } label: {
                        Text("Create")
                    }
                    .disabled(self.name.isEmpty)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct NewCompsimView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    @Binding var showNewSessionPopUp: Bool
    @Binding var currentSession: Sessions
    @State private var name: String = ""
    @State private var targetStr: String = ""
    @State private var sessionEventType: Int32 = 0
    @State var pinnedSession: Bool
    
    @ScaledMetric(relativeTo: .body) var frameHeight: CGFloat = 45
    @ScaledMetric(relativeTo: .title2) var bigFrameHeight: CGFloat = 80

    
    let sessionEventTypeColumns = [GridItem(.adaptive(minimum: 40))]
    
    var body: some View {
        ZStack {
            Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                .ignoresSafeArea()
            
            ScrollView {
                VStack (spacing: 16) {
                    
                    VStack (alignment: .center, spacing: 0) {
                        Image(puzzle_types[Int(sessionEventType)].name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .padding(.top)
                            .padding(.bottom)
                            .shadow(color: .black.opacity(0.24), radius: 12, x: 0, y: 4)
                        
                        
                        TextField("Session Name", text: $name)
                            .padding(12)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(TextAlignment.center)
                            .background(Color(uiColor: .systemGray5))
                            .cornerRadius(10)
                            .padding(.leading)
                            .padding(.trailing)
                            .padding(.bottom)
                        
                        Text("A comp sim (Competition Simulation) session mimics a competition scenario better by recording a non-rolling session. Your solves will be split up into averages of 5 that can be accessed in your times and statistics view.\n\nStart by choosing a target to reach.")
                        /// todo: add ability to target your wca pb/some ranking/some official record
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color(uiColor: .systemGray))
                            .padding(.horizontal)
                            .padding(.bottom)
                        
                    }
                    .frame(minHeight: bigFrameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    VStack (spacing: 0) {
                        HStack {
                            Text("Target")
                                .font(.body.weight(.medium))
                            
                            Spacer()
                            
                            TextField("0.00", text: $targetStr)
                                .multilineTextAlignment(.trailing)
                                .modifier(TimeMaskTextField(text: $targetStr))
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    VStack (spacing: 0) {
                        HStack {
                            Text("Session Event")
                                .font(.body.weight(.medium))
                            
                            
                            Spacer()
                            
                            Picker("", selection: $sessionEventType) {
                                ForEach(Array(puzzle_types.enumerated()), id: \.offset) {index, element in
                                    Text(element.name).tag(Int32(index))
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(accentColour)
                            .font(.body)
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    
                    VStack (spacing: 0) {
                        LazyVGrid(columns: sessionEventTypeColumns, spacing: 0) {
                            ForEach(Array(zip(puzzle_types.indices, puzzle_types)), id: \.0) { index, element in
                                Button {
                                    sessionEventType = Int32(index)
                                } label: {
                                    ZStack {
                                        Image("circular-" + element.name)
                                        
                                        Circle()
                                            .strokeBorder(Color(uiColor: .systemGray3), lineWidth: (index == sessionEventType) ? 3 : 0)
                                            .frame(width: 54, height: 54)
                                            .offset(x: -0.2)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(height: 180)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    
                    
                    VStack (spacing: 0) {
                        HStack {
                            Toggle(isOn: $pinnedSession) {
                                Text("Pin Session?")
                                    .font(.body.weight(.medium))
                            }
                            .tint(.yellow)
                        }
                        .padding()
                    }
                    .frame(height: frameHeight)
                    .modifier(NewStandardSessionViewBlocks())
                    
                    Spacer()
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("New Comp Sim Session", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let sessionItem = CompSimSession(context: managedObjectContext)
                        sessionItem.name = name
                        sessionItem.pinned = pinnedSession
                        
                        sessionItem.session_type = 4
                        
                        sessionItem.target = timeFromStr(targetStr)!
                        
                        sessionItem.scramble_type = sessionEventType
                        try! managedObjectContext.save()
                        currentSession = sessionItem
                        showNewSessionPopUp = false
                    } label: {
                        Text("Create")
                    }
                    .disabled(self.name.isEmpty || self.targetStr.isEmpty)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}



/// **Main session views**
struct SessionsView: View {
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    @Binding var currentSession: Sessions
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    
    
    
    @State var showNewSessionPopUp = false
    
    
    
    // I know that this is bad
    // I tried to use SectionedFetchRequest to no avail
    // send a PR if you can make this good :)
    @FetchRequest(
        entity: Sessions.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Sessions.name, ascending: true)
        ],
        predicate: NSPredicate(format: "pinned == YES")
    ) var pinnedSessions: FetchedResults<Sessions>
    
    @FetchRequest(
        entity: Sessions.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Sessions.name, ascending: true)
        ],
        predicate: NSPredicate(format: "pinned == NO")
    ) var unPinnedSessions: FetchedResults<Sessions>
    
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack (spacing: 10) {
                        ForEach(pinnedSessions) { item in
                            SessionCard(currentSession: $currentSession, item: item, numSessions: pinnedSessions.count + unPinnedSessions.count)
                                .environment(\.managedObjectContext, managedObjectContext)
                            
                        }
                        ForEach(unPinnedSessions) { item in
                            SessionCard(currentSession: $currentSession, item: item, numSessions: pinnedSessions.count + unPinnedSessions.count)
                                .environment(\.managedObjectContext, managedObjectContext)
                            
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.clear).frame(height: 50).padding(.top, 64).padding(.bottom, SetValues.hasBottomBar ? 0 : nil)}
                
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            showNewSessionPopUp = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2.weight(.semibold))
                                .padding(.leading, -5)
                            Text("New Session")
                                .font(.headline.weight(.medium))
                                .padding(.leading, -2)
                        }
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 3)
                        .overlay(Capsule().stroke(Color.black.opacity(0.05), lineWidth: 0.5))
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .background(.ultraThinMaterial, in: Capsule())
                        .sheet(isPresented: $showNewSessionPopUp) {
                            NewSessionPopUpView(currentSession: $currentSession, showNewSessionPopUp: $showNewSessionPopUp)
                                .environment(\.managedObjectContext, managedObjectContext)
                        }
                        .padding(.leading)
                        .padding(.bottom, 8)
                        
                        Spacer()
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.clear).frame(height: 50).padding(.bottom, SetValues.hasBottomBar ? 0 : nil)}
            }
            .navigationTitle("Your Sessions")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
