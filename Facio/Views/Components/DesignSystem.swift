import SwiftUI

enum FacioLayout {
    static let screenPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 18
    static let panelRadius: CGFloat = 8
    static let rowRadius: CGFloat = 7
    static let inspectorWidth: CGFloat = 280
    static let documentInspectorBreakpoint: CGFloat = 1120
}

enum InlineTone {
    case info
    case success
    case warning
    case danger

    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .danger: return .red
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .danger: return "xmark.octagon"
        }
    }
}

struct SectionPanel<Content: View>: View {
    let title: String?
    let systemImage: String?
    let content: Content

    init(_ title: String? = nil, systemImage: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                Label(title, systemImage: systemImage ?? "square.grid.2x2")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .labelStyle(.titleAndIcon)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: FacioLayout.panelRadius)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.panelRadius))
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var subtitle: String?
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(value)
                    .font(.title2.monospacedDigit())
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(" ")
                        .font(.caption2)
                        .lineLimit(2)
                        .hidden()
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.68))
        .overlay(
            RoundedRectangle(cornerRadius: FacioLayout.panelRadius)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.panelRadius))
    }
}

struct ActionTile: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var tone: InlineTone = .info
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tone.color)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: FacioLayout.panelRadius))
        }
        .buttonStyle(.plain)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.panelRadius))
    }
}

struct FacioListRow<Content: View>: View {
    var tone: Color = .primary
    let content: Content

    @State private var isHovering = false

    init(tone: Color = .primary, @ViewBuilder content: () -> Content) {
        self.tone = tone
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tone.opacity(0.75))
                .frame(width: 3)
            content
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(nsColor: .textBackgroundColor)
                .opacity(isHovering ? 0.9 : 0.62)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FacioLayout.rowRadius)
                .strokeBorder(Color.primary.opacity(isHovering ? 0.12 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.rowRadius))
        .contentShape(RoundedRectangle(cornerRadius: FacioLayout.rowRadius))
        .onHover { isHovering = $0 }
    }
}

struct InlineWarning: View {
    let text: String
    var tone: InlineTone = .warning

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: tone.icon)
                .foregroundStyle(tone.color)
            Text(text)
                .font(.caption)
                .foregroundStyle(tone.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(tone.color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct ChecklistRow: View {
    let title: String
    var detail: String?
    let isComplete: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? .green : .secondary)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct InspectorPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: FacioLayout.inspectorWidth)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
