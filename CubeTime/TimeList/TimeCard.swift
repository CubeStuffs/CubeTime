import SwiftUI
import CoreData



struct TimeCard: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    @EnvironmentObject var stopwatchManager: StopwatchManager
    
    var solve: Solves
    
    let formattedTime: String
    let pen: PenTypes
    
    @Binding var currentSolve: Solves?
    @Binding var isSelectMode: Bool
    
    @Binding var selectedSolves: Set<Solves>
    
    var isSelected = false
    
    @Environment(\.sizeCategory) var sizeCategory
    
    private var cardWidth: CGFloat {
        if sizeCategory > ContentSizeCategory.extraLarge {
            return 200
        } else if sizeCategory < ContentSizeCategory.small {
            return 100
        } else {
            return 120
        }
    }
    
    private var cardHeight: CGFloat {
        if sizeCategory > ContentSizeCategory.extraLarge {
            return 60
        } else if sizeCategory < ContentSizeCategory.small {
            return 50
        } else {
            return 55
        }
    }
    
    init(solve: Solves, currentSolve: Binding<Solves?>, isSelectMode: Binding<Bool>, selectedSolves: Binding<Set<Solves>>) {
        self.solve = solve
        self.formattedTime = formatSolveTime(secs: solve.time, penType: PenTypes(rawValue: solve.penalty)!)
        self.pen = PenTypes(rawValue: solve.penalty)!
        self._currentSolve = currentSolve
        self._isSelectMode = isSelectMode
        self._selectedSolves = selectedSolves
        self.isSelected = selectedSolves.wrappedValue.contains(solve)
    }
    
    var body: some View {
        let sess_type = stopwatchManager.currentSession.session_type
        ZStack {
            #warning("TODO:  check operforamcne of the on tap/long hold gestures on the zstack vs the rounded rectangle")
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected
                      ? Color("indent0")
                      : Color("overlay0"))
                .frame(maxWidth: cardWidth, minHeight: cardHeight, maxHeight: cardHeight)

                .onTapGesture {
                    if isSelectMode {
                        withAnimation(Animation.customDampedSpring) {
                            if isSelected {
//                                isSelected = false
                                selectedSolves.remove(solve)
                            } else {
//                                isSelected = true
                                selectedSolves.insert(solve)
                            }
                        }
                    } else {
                        currentSolve = solve
                    }
                }
                .onLongPressGesture {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
                
                
            VStack {
                Text(formattedTime)
                    .font(.body.weight(.bold))
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("accent"))
                }
            }
        }
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 8, style: .continuous))


        .contextMenu {
            Button {
                copySolve(solve: solve)
            } label: {
                Label {
                    Text("Copy")
                } icon: {
                    Image(systemName: "doc.on.doc")
                }
            }
            
            Menu {
                Button {
                    stopwatchManager.changePen(solve: self.solve, pen: .none)
                } label: {
                    Label("No Penalty", systemImage: "checkmark.circle")
                }
                
                Button {
                    stopwatchManager.changePen(solve: self.solve, pen: .plustwo)
                } label: {
                    Label("+2", image: "+2.label")
                }
                
                Button {
                    stopwatchManager.changePen(solve: self.solve, pen: .dnf)
                } label: {
                    Label("DNF", systemImage: "xmark.circle")
                }
            } label: {
                Label("Penalty", systemImage: "exclamationmark.triangle")
            }
            
            if sess_type != SessionTypes.compsim.rawValue {
                SessionPickerMenu(sessions: sess_type == SessionTypes.playground.rawValue ? stopwatchManager.sessionsCanMoveToPlayground[Int(solve.scramble_type)] : stopwatchManager.sessionsCanMoveTo) { session in
                    withAnimation(Animation.customDampedSpring) {
                        stopwatchManager.moveSolve(solve: solve, to: session)
                    }
                }
            }
            
            
            Divider()
            
            
            Button(role: .destructive) {
                managedObjectContext.delete(solve)
                try! managedObjectContext.save()
                stopwatchManager.tryUpdateCurrentSolveth()
                
                withAnimation(Animation.customDampedSpring) {
                    stopwatchManager.delete(solve: solve)
                }
            } label: {
                Label {
                    Text("Delete")
                } icon: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}
