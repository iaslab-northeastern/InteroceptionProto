//
//  NavigationStack.swift
//  BioBaseRedux
//
//  Created by Matteo Puccinelli on 28/11/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import SwiftUI

enum NavigationTransition {
    case none
    case `default`
    case symmetric(AnyTransition)
    case asymmetric(push: AnyTransition, pop: AnyTransition)

    fileprivate static var defaultTransitions: (push: AnyTransition, pop: AnyTransition) {
        let pushTrans = AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        let popTrans = AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        return (pushTrans, popTrans)
    }

    fileprivate static var defaultEasing: Animation {
        .easeIn(duration: 0.3)
    }
}

private enum NavigationType {
    case push
    case pop
}

enum PopDestination {
    case previous
    case root
    case backTwo
    case to(String)
}

enum NavigationStackError: Error {
    case viewNotFound
}

class NavigationViewModel: ObservableObject {
    fileprivate private(set) var navigationType = NavigationType.push
    private var viewStack = ViewStack() {
        didSet {
            peek = viewStack.peek()?.wrappedElement
        }
    }

    @Published var peek: AnyView?

    func push(_ element: AnyView, withId id: String? = nil) {
        viewStack.push(ViewElement(id: id == nil ? UUID().uuidString : id!, wrappedElement: AnyView(element)))
        navigationType = .push
    }

    func pop(to: PopDestination) {
        switch to {
        case .root:
            viewStack.popToRoot()
        case .backTwo:
            viewStack.popToPrevious()
            viewStack.popToPrevious()
        case .to(let viewId):
            viewStack.popTo(id: viewId)
        default:
            viewStack.popToPrevious()
        }
        navigationType = .pop
    }

    //the actual stack
    private struct ViewStack {
        private var views = [ViewElement]()

        func peek() -> ViewElement? {
            views.last
        }

        mutating func push(_ element: ViewElement) {
            views.append(element)
        }

        mutating func popToPrevious() {
            _ = views.popLast()
        }

        mutating func popTo(id: String) {
            guard let viewIndex = (views.firstIndex {
                $0.id == id
            }) else {
                return
            }
            views.removeLast(views.count - (viewIndex + 1))
        }

        mutating func popToRoot() {
            views.removeAll()
        }
    }

    //the collection element
    private struct ViewElement: Identifiable, Equatable {
        let id: String
        let wrappedElement: AnyView

        static func == (lhs: ViewElement, rhs: ViewElement) -> Bool {
            lhs.id == rhs.id
        }
    }
}

struct NavigationStackKey: EnvironmentKey {
    static var defaultValue = NavigationViewModel()
}

extension EnvironmentValues {
    var navigationStack: NavigationViewModel {
        get {
            return self[NavigationStackKey.self]
        }
        set {
            self[NavigationStackKey.self] = newValue
        }
    }
}

struct NavigationStackView<Root>: View where Root: View {
    @ObservedObject private var navViewModel = NavigationViewModel()
    private let rootView: Root
    private let transitions: (push: AnyTransition, pop: AnyTransition)

    init(transitionType: NavigationTransition = .default, @ViewBuilder rootView: () -> Root) {
        self.rootView = rootView()
        switch transitionType {
        case .none:
            self.transitions = (.identity, .identity)
        case .symmetric(let trans):
            self.transitions = (trans, trans)
        case .asymmetric(let pushTrans, let popTrans):
            self.transitions = (pushTrans, popTrans)
        default:
            self.transitions = NavigationTransition.defaultTransitions
        }
    }

    var body: some View {
        let showRoot = navViewModel.peek == nil
        let navigationType = navViewModel.navigationType

        return ZStack () {
            Group {
                if showRoot {
                    rootView
                        .transition(navigationType == .push ? transitions.push : transitions.pop)
                        .environmentObject(navViewModel)
                } else {
                    navViewModel.peek
                        .transition(navigationType == .push ? transitions.push : transitions.pop)
                        .environmentObject(navViewModel)
                }
            }
        }
    }
}

struct PushView<Label, Destination>: View where Label: View, Destination: View {
    @EnvironmentObject private var navViewModel: NavigationViewModel
    private let label: Label
    private let destinationId: String?
    private let destination: Destination
    @Binding var isActive: Bool

    init(_ destination: Destination, withId id: String? = nil, isActive: Binding<Bool> = .constant(false), @ViewBuilder withLabel label: () -> Label) {
        self.label = label()
        self.destinationId = id
        self._isActive = isActive
        self.destination = destination
    }

    var body: some View {
        if isActive {
            DispatchQueue.main.async {
                self.isActive = false
                withAnimation(NavigationTransition.defaultEasing) {
                    self.navViewModel.push(AnyView(self.destination), withId: self.destinationId)
                }
            }
        }
        return label.onTapGesture {
            withAnimation(NavigationTransition.defaultEasing) {
                self.navViewModel.push(AnyView(self.destination), withId: self.destinationId)
            }
        }
    }
}

struct PopView<Label>: View where Label: View {
    @EnvironmentObject private var navViewModel: NavigationViewModel
    private let label: Label
    private let destination: PopDestination
    @Binding var isActive: Bool

    init(to destination: PopDestination = .previous, isActive: Binding<Bool> = .constant(false), @ViewBuilder withLabel label: () -> Label) {
        self.label = label()
        self.destination = destination
        self._isActive = isActive
    }

    var body: some View {
        if isActive {
            DispatchQueue.main.async {
                self.isActive = false
                withAnimation(NavigationTransition.defaultEasing) {
                    self.navViewModel.pop(to: self.destination)
                }
            }
        }
        return label.onTapGesture {
            withAnimation(NavigationTransition.defaultEasing) {
                self.navViewModel.pop(to: self.destination)
            }
        }
    }
}

struct NavigationTest3: View {
    var body: some View {
        VStack {
            Color.gray
            Text("Hello World3!")
            Spacer()
            PopView(to: .to("two")) {
                Text("POP!")
            }
        }
    }
}

struct NavigationTest2: View {
    @State private var isActive = false
    var body: some View {
        ZStack {
            Color.green
            VStack {
                Text("Hello World2!")
                Spacer()
                PushView(NavigationTest3()) {
                    Text("PUSH!")
                }                
                PopView(isActive: $isActive) {
                    Text("POP!")
                }
                
                Button(action: {
                    self.isActive.toggle()
                }, label: {
                    Text("Programmatic POP!!!!!")
                })
            }
        }
    }
}

struct NavigationTest: View {
    @State private var isActive = false
    var body: some View {
        NavigationStackView {
            ZStack {
                Color.yellow
                VStack {
                    Text("Hello World!")
                    Spacer()
                    PushView(NavigationTest2(), withId: "two", isActive: $isActive) {
                        Text("PUSH ME!")
                    }
                    Button(action: {
                        self.isActive.toggle()
                    }, label: {
                        Text("Programmatic PUSH!")
                    })
                }
            }
        }
    }
}

struct NavigationStack_Previews: PreviewProvider {
    static var previews: some View {
        NavigationTest()
    }
}
