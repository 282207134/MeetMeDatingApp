import SwiftUI

struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 16) {
                            Spacer(minLength: 12)
                            Image("MeetMeMark").resizable().scaledToFit().frame(width: 128, height: 130)
                            Text("Meetme").font(.system(size: 38, weight: .bold, design: .rounded))
                            Text("Swipe. Like. Connect.").font(.headline).opacity(0.94)
                            Spacer(minLength: 16)
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: max(310, geometry.size.height * 0.46))
                        .background(Theme.gradient).clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 48, bottomTrailingRadius: 48))
                        VStack(spacing: 16) {
                            VStack(spacing: 10) {
                                Text("A little hello.\nA whole new possibility.")
                                    .font(.system(.title, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
                                Text("Meet someone who makes everyday\nfeel a little more extraordinary.")
                                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(4)
                            }.padding(.bottom, 12)
                            NavigationLink { AuthForm(createAccount: true) } label: {
                                Text("Create an account").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 48)
                            }.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 16)).accessibilityIdentifier("create-account")
                            NavigationLink { AuthForm(createAccount: false) } label: {
                                Text("I already have an account").font(.headline).frame(maxWidth: .infinity).frame(height: 44)
                            }.buttonStyle(.bordered).buttonBorderShape(.roundedRectangle(radius: 16))
                            Button("Explore the demo", action: store.startDemo).font(.subheadline.weight(.semibold)).padding(.top, 4).accessibilityIdentifier("start-demo")
                            Text("A local demo for adults 18+. Your data stays on this device.")
                                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.top, 6)
                        }.padding(28)
                    }.frame(minHeight: geometry.size.height)
                }.ignoresSafeArea(edges: .top)
            }
            .toolbar(.hidden, for: .navigationBar).background(Color(.systemBackground))
        }
    }
}

struct AuthForm: View {
    private enum Field: Hashable { case name, email, password }
    @Environment(AppStore.self) private var store
    let createAccount: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var adult = false
    @FocusState private var focusedField: Field?
    private var valid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6 && (!createAccount || (!name.trimmingCharacters(in: .whitespaces).isEmpty && adult))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image("MeetMeMark").resizable().scaledToFit().frame(width: 64, height: 66).padding(.top, 20)
                VStack(alignment: .leading, spacing: 8) {
                    Text(createAccount ? "Your next chapter\nstarts here." : "Welcome back.").font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text(createAccount ? "Let’s get to know the person behind the profile." : "Your connections are waiting for you.").font(.subheadline).foregroundStyle(.secondary)
                }
                VStack(spacing: 16) {
                    if createAccount { entry("Your first name", text: $name, id: "auth-name", field: .name).textContentType(.givenName) }
                    entry("Email address", text: $email, id: "auth-email", field: .email).keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                    // This form does not create a remote credential or enroll a password manager.
                    SecureField("Password · at least 6 characters", text: $password).textContentType(nil)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().focused($focusedField, equals: .password)
                        .submitLabel(.done).onSubmit { focusedField = nil }
                        .padding(18).background(Theme.canvas, in: RoundedRectangle(cornerRadius: 14)).accessibilityIdentifier("auth-password")
                }
                if createAccount { Toggle("I’m 18 or older", isOn: $adult).font(.subheadline).accessibilityIdentifier("adult-confirmation") }
                PrimaryButton(title: createAccount ? "Create local account" : "Continue", icon: "arrow.right") {
                    store.signIn(name: name, email: email, create: createAccount)
                }.disabled(!valid).accessibilityIdentifier("auth-submit")
                Label("Local demonstration", systemImage: "iphone").font(.caption.weight(.semibold)).foregroundStyle(Theme.blue)
                Text("No remote account is created. The password validates this demo form and is never saved. Use the demo button on the welcome screen to skip registration.")
                    .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
            }.padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(createAccount ? "Create account" : "Sign in").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }.accessibilityIdentifier("keyboard-done")
            }
        }
    }
    private func entry(_ title: String, text: Binding<String>, id: String, field: Field) -> some View {
        TextField(title, text: text).focused($focusedField, equals: field).submitLabel(.next)
            .onSubmit { focusedField = field == .name ? .email : .password }
            .padding(18).background(Theme.canvas, in: RoundedRectangle(cornerRadius: 14)).accessibilityIdentifier(id)
    }
}

struct ProfileSetupView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0
    @State private var draft = UserProfile()
    private let titles = ["Be yourself.", "Find your common ground.", "You’re ready to connect."]
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("YOUR PROFILE").font(.caption.weight(.bold)).tracking(2).foregroundStyle(Theme.blue)
                    Spacer()
                    Text("\(step + 1) of 3").font(.caption).foregroundStyle(.secondary)
                }.padding(.horizontal, 24)
                ProgressView(value: Double(step + 1), total: 3).padding(.horizontal, 24)
                Text(titles[step]).font(.system(.title, design: .rounded, weight: .bold)).padding(.horizontal, 24)
                if step == 0 {
                    Form {
                        Section("The basics") {
                            TextField("First name", text: $draft.name).accessibilityIdentifier("setup-name")
                            Picker("Age", selection: $draft.age) { ForEach(18..<100) { Text("\($0)").tag($0) } }
                            Picker("I identify as", selection: $draft.gender) { ForEach(["Man", "Woman", "Non-binary", "Prefer not to say"], id: \.self) { Text($0) } }
                            TextField("City", text: $draft.city)
                        }
                        Section("What brings you here?") {
                            Picker("Looking for", selection: $draft.intention) { ForEach(["A meaningful connection", "A long-term relationship", "New friends", "Still figuring it out"], id: \.self) { Text($0) } }
                        }
                    }.scrollContentBackground(.hidden)
                } else if step == 1 {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Choose at least 3 things you love. The best conversations start with something in common.").foregroundStyle(.secondary)
                            InterestPicker(selection: $draft.interests)
                            Text("\(draft.interests.count) interests selected").font(.caption).foregroundStyle(Theme.blue)
                        }.padding(.horizontal, 24)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            MyAvatar(profile: draft, size: 140).shadow(color: Theme.blue.opacity(0.1), radius: 16)
                            Text("\(draft.name), \(draft.age)").font(.system(.title2, design: .rounded, weight: .bold))
                            Label(draft.city, systemImage: "mappin.and.ellipse").foregroundStyle(.secondary)
                            InterestChips(items: draft.interests)
                            Text("We’ve used a sample photo for this local demo. You can add your own from Edit Profile at any time.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }.padding(24)
                    }
                }
                Spacer(minLength: 0)
                PrimaryButton(title: step == 2 ? "Start discovering" : "Continue", icon: "arrow.right") {
                    if step < 2 { withAnimation { step += 1 } } else { store.finishProfile(draft) }
                }.disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || (step == 1 && draft.interests.count < 3)).padding(.horizontal, 24).padding(.bottom, 16).accessibilityIdentifier("setup-next")
            }
            .background(Theme.canvas).navigationTitle("Complete your profile").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { if step > 0 { Button { step -= 1 } label: { Image(systemName: "chevron.left") } } } }
            .onAppear { draft = store.state.user }
        }
    }
}

struct InterestPicker: View {
    @Binding var selection: [String]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96))], spacing: 12) {
            ForEach(Theme.interests, id: \.self) { interest in
                let selected = selection.contains(interest)
                Button {
                    if selected { selection.removeAll { $0 == interest } } else { selection.append(interest) }
                } label: {
                    Text(interest).font(.subheadline.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .foregroundStyle(selected ? .white : Theme.ink)
                        .background(selected ? Color.accentColor : Color(.systemBackground), in: Capsule())
                        .overlay(Capsule().stroke(selected ? Color.clear : Color.gray.opacity(0.2)))
                }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
