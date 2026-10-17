import SwiftUI

enum Theme {
    static let ink = Color("Ink")
    static let blue = Color("BrandBlue")
    static let cyan = Color("BrandCyan")
    static let canvas = Color("Canvas")
    static let gradient = LinearGradient(colors: [Color("BrandCyan"), Color.accentColor], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let interests = ["Travel", "Coffee", "Music", "Art", "Hiking", "Books", "Movies", "Food", "Design", "Fitness", "Gaming", "Pets"]
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                if let icon { Image(systemName: icon) }
            }
            .font(.system(.headline, design: .rounded)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(minHeight: 54)
        }
        .buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 16))
    }
}

struct BrandHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(.title, design: .rounded, weight: .bold))
                Text(subtitle).font(.subheadline).opacity(0.9)
            }
            Spacer()
            Image("MeetMeMark").resizable().scaledToFit().frame(width: 52, height: 56)
        }
        .foregroundStyle(.white).padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 24)
        .background { Theme.gradient.ignoresSafeArea(edges: .top).clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30)) }
    }
}

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 54
    var body: some View {
        Image(person.image).resizable().scaledToFill().frame(width: size, height: size).clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3))
    }
}

struct MyAvatar: View {
    let profile: UserProfile
    var size: CGFloat = 100
    var body: some View {
        Group {
            if profile.hasCustomPhoto, let image = UIImage(contentsOfFile: AppStore.photoURL.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else { Image("AvatarMe").resizable().scaledToFill() }
        }
        .frame(width: size, height: size).clipShape(Circle()).overlay(Circle().stroke(.white, lineWidth: 4))
    }
}

struct InterestChips: View {
    let items: [String]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item).font(.subheadline.weight(.medium)).padding(.vertical, 10).frame(maxWidth: .infinity)
                    .background(Theme.cyan.opacity(0.14), in: Capsule()).foregroundStyle(Theme.blue)
            }
        }
    }
}

struct EmptyCard: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 46, weight: .light)).foregroundStyle(Theme.gradient).padding(22).background(Theme.cyan.opacity(0.12), in: Circle())
            Text(title).font(.system(.title2, design: .rounded, weight: .bold))
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(4)
        }.frame(maxWidth: .infinity).padding(28)
    }
}

struct ToastOverlay: View {
    let text: String
    var body: some View {
        Text(text).font(.subheadline.weight(.medium)).multilineTextAlignment(.center)
            .padding(.horizontal, 20).padding(.vertical, 14).background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6).padding(.horizontal, 24).padding(.bottom, 90)
            .accessibilityIdentifier("toast")
    }
}
