import AppKit
import SwiftUI

private struct BrandMark: View {
  let size: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
        .fill(
          LinearGradient(
            colors: [StudioColors.coralBright, StudioColors.coral],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      Image(systemName: "paintpalette.fill")
        .font(.system(size: size * 0.46, weight: .bold))
        .foregroundStyle(.white)
    }
    .frame(width: size, height: size)
    .shadow(color: StudioColors.coral.opacity(0.28), radius: 14, y: 7)
    .accessibilityHidden(true)
  }
}

struct StatusHeader: View {
  @EnvironmentObject private var controller: SkinController
  var compact = false

  private var needsAttention: Bool {
    controller.status.session == "stale" || controller.status.session == "unknown"
  }

  var body: some View {
    HStack(spacing: compact ? 10 : 13) {
      BrandMark(size: compact ? 34 : 42)
      VStack(alignment: .leading, spacing: 2) {
        Text("CODEX DREAM SKIN")
          .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
          .tracking(1.1)
          .foregroundStyle(StudioColors.text)
        Text(controller.isBusy ? controller.progressMessage : "本地主题控制台")
          .font(.system(size: 11))
          .foregroundStyle(StudioColors.muted)
          .lineLimit(1)
      }
      Spacer(minLength: 12)
      if controller.isBusy {
        ProgressView()
          .controlSize(.small)
          .tint(StudioColors.coralBright)
      } else {
        StudioStatusPill(
          text: controller.status.displayText,
          isActive: controller.status.isActive,
          needsAttention: needsAttention
        )
      }
    }
  }
}

private struct ThemeArtwork: View {
  let theme: ThemeDescriptor

  private var image: NSImage? {
    NSImage(contentsOf: theme.previewURL)
  }

  var body: some View {
    Group {
      if let image {
        Image(nsImage: image)
          .resizable()
          .scaledToFill()
      } else {
        LinearGradient(
          colors: [StudioColors.canvasRaised, StudioColors.canvas],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    }
  }
}

struct ThemeRow: View {
  @EnvironmentObject private var controller: SkinController
  let theme: ThemeDescriptor

  var body: some View {
    Button {
      controller.selectTheme(theme)
    } label: {
      HStack(spacing: 11) {
        ThemeArtwork(theme: theme)
          .frame(width: 72, height: 42)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        VStack(alignment: .leading, spacing: 3) {
          Text(theme.name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(StudioColors.text)
            .lineLimit(1)
          Text(theme.category.label)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(StudioColors.muted)
        }
        Spacer()
        if controller.selectedThemeID == theme.id {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(StudioColors.mint)
        }
      }
      .padding(7)
      .background(
        controller.selectedThemeID == theme.id
          ? StudioColors.mint.opacity(0.08)
          : Color.clear,
        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(controller.isBusy)
    .accessibilityHint("选择并应用此主题")
  }
}

struct MenuContentView: View {
  @EnvironmentObject private var controller: SkinController

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      StatusHeader(compact: true)

      if let selected = controller.selectedTheme {
        ZStack(alignment: .bottomLeading) {
          ThemeArtwork(theme: selected)
            .frame(height: 104)
            .clipped()
          LinearGradient(
            colors: [.clear, Color.black.opacity(0.78)],
            startPoint: .top,
            endPoint: .bottom
          )
          VStack(alignment: .leading, spacing: 2) {
            Text(selected.name)
              .font(.system(size: 15, weight: .bold))
            Text(selected.summary)
              .font(.system(size: 10))
              .foregroundStyle(.white.opacity(0.72))
              .lineLimit(1)
          }
          .foregroundStyle(.white)
          .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(StudioColors.line, lineWidth: 1)
        )
      }

      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("启用皮肤")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(StudioColors.text)
          Text("仅在切换状态时重启一次 Codex")
            .font(.system(size: 10))
            .foregroundStyle(StudioColors.muted)
        }
        Spacer()
        Toggle(
          "",
          isOn: Binding(
            get: { controller.desiredEnabled },
            set: { controller.setSkinEnabled($0) }
          )
        )
        .labelsHidden()
        .toggleStyle(.switch)
        .tint(StudioColors.coral)
        .disabled(controller.isBusy || !controller.engineAvailable)
        .accessibilityLabel("启用 Codex 皮肤")
      }

      VStack(alignment: .leading, spacing: 7) {
        Text("快速切换")
          .font(.system(size: 10, weight: .bold))
          .tracking(0.8)
          .foregroundStyle(StudioColors.muted)
        ScrollView {
          LazyVStack(spacing: 3) {
            ForEach(controller.themes) { theme in
              ThemeRow(theme: theme)
            }
          }
        }
        .frame(maxHeight: 218)
      }

      if let error = controller.lastError {
        ErrorPanel(error: error)
      }

      HStack(spacing: 8) {
        Button("打开工作台") { SettingsWindowController.shared.show() }
          .buttonStyle(StudioPrimaryButtonStyle())
        Button("导入图片") { controller.importBackground() }
          .buttonStyle(StudioSecondaryButtonStyle())
        Spacer()
        Button {
          controller.quitApplication()
        } label: {
          Image(systemName: "power")
        }
        .buttonStyle(.plain)
        .foregroundStyle(StudioColors.muted)
        .help("退出管理器")
      }
      .disabled(controller.isBusy)
    }
    .padding(16)
    .frame(width: 400)
    .studioWindowBackground()
    .preferredColorScheme(.dark)
  }
}

private struct ThemeHero: View {
  @EnvironmentObject private var controller: SkinController
  let theme: ThemeDescriptor?

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      if let theme {
        ThemeArtwork(theme: theme)
      } else {
        LinearGradient(
          colors: [StudioColors.canvasRaised, StudioColors.canvas],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
      LinearGradient(
        colors: [Color.black.opacity(0.05), Color.black.opacity(0.82)],
        startPoint: .top,
        endPoint: .bottom
      )
      HStack(alignment: .bottom, spacing: 20) {
        VStack(alignment: .leading, spacing: 7) {
          Text("当前主题")
            .font(.system(size: 10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(.white.opacity(0.62))
          Text(theme?.name ?? "尚未选择")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
          Text(theme?.summary ?? "从下方主题库选择一套皮肤")
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.72))
            .lineLimit(2)
        }
        Spacer()
        Button(controller.desiredEnabled ? "关闭皮肤" : "开启皮肤") {
          controller.setSkinEnabled(!controller.desiredEnabled)
        }
        .buttonStyle(StudioPrimaryButtonStyle())
        .disabled(controller.isBusy || !controller.engineAvailable)
      }
      .padding(24)
    }
    .frame(minHeight: 238)
    .clipped()
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(StudioColors.line, lineWidth: 1)
    )
  }
}

private struct AutomationPanel: View {
  @EnvironmentObject private var controller: SkinController

  var body: some View {
    StudioPanel {
      VStack(alignment: .leading, spacing: 16) {
        Label("自动化", systemImage: "bolt.fill")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(StudioColors.text)
        AutomationToggle(
          title: "登录时启动",
          detail: "由 macOS 登录项托管",
          isOn: Binding(
            get: { controller.loginItemState == .enabled },
            set: { controller.setLaunchAtLogin($0) }
          )
        )
        AutomationToggle(
          title: "自动打开 Codex",
          detail: "管理器启动后自动恢复皮肤",
          isOn: $controller.autoOpenCodex
        )
        AutomationToggle(
          title: "接管普通启动",
          detail: "检测到无皮肤启动时只重启一次",
          isOn: $controller.autoRepairLaunch
        )

        if controller.loginItemState == .requiresApproval {
          Button("前往系统设置批准") {
            controller.openLoginItemSettings()
          }
          .buttonStyle(StudioSecondaryButtonStyle())
        }

        Divider().overlay(StudioColors.line)
        Text("自动接管有 90 秒冷却保护；手动退出 Codex 后不会擅自重开。")
          .font(.system(size: 10))
          .foregroundStyle(StudioColors.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(18)
    }
  }
}

private struct AutomationToggle: View {
  let title: String
  let detail: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(StudioColors.text)
        Text(detail)
          .font(.system(size: 10))
          .foregroundStyle(StudioColors.muted)
      }
      Spacer()
      Toggle("", isOn: $isOn)
        .labelsHidden()
        .toggleStyle(.switch)
        .controlSize(.small)
        .tint(StudioColors.coral)
        .accessibilityLabel(title)
    }
  }
}

struct ThemeCard: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @EnvironmentObject private var controller: SkinController
  @State private var isHovering = false
  let theme: ThemeDescriptor

  private var isSelected: Bool {
    controller.selectedThemeID == theme.id
  }

  var body: some View {
    Button {
      controller.selectTheme(theme)
    } label: {
      VStack(alignment: .leading, spacing: 0) {
        ZStack(alignment: .topTrailing) {
          ThemeArtwork(theme: theme)
            .frame(height: 134)
            .clipped()
          if isSelected {
            Label("已选择", systemImage: "checkmark")
              .font(.system(size: 10, weight: .bold))
              .foregroundStyle(Color.black.opacity(0.78))
              .padding(.horizontal, 9)
              .frame(height: 24)
              .background(StudioColors.mint, in: Capsule())
              .padding(10)
          } else if theme.isFeatured {
            Text("推荐")
              .font(.system(size: 10, weight: .bold))
              .foregroundStyle(.white)
              .padding(.horizontal, 9)
              .frame(height: 24)
              .background(Color.black.opacity(0.48), in: Capsule())
              .padding(10)
          }
        }

        VStack(alignment: .leading, spacing: 7) {
          HStack {
            Text(theme.name)
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(StudioColors.text)
              .lineLimit(1)
            Spacer()
            Text(theme.category.label)
              .font(.system(size: 9, weight: .bold))
              .foregroundStyle(StudioColors.muted)
              .padding(.horizontal, 7)
              .frame(height: 20)
              .background(StudioColors.surface, in: Capsule())
          }
          Text(theme.summary)
            .font(.system(size: 10))
            .foregroundStyle(StudioColors.muted)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 27, alignment: .topLeading)
        }
        .padding(13)
      }
      .background(isHovering ? StudioColors.surfaceHover : StudioColors.surface)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(isSelected ? StudioColors.mint.opacity(0.65) : StudioColors.line, lineWidth: isSelected ? 1.5 : 1)
      )
      .scaleEffect(isHovering ? 1.012 : 1)
      .shadow(color: Color.black.opacity(isHovering ? 0.25 : 0.08), radius: isHovering ? 16 : 6, y: 7)
      .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(controller.isBusy)
    .onHover { isHovering = $0 }
    .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovering)
    .accessibilityLabel("\(theme.name)，\(theme.category.label)")
    .accessibilityHint(isSelected ? "当前已选择" : "选择并应用此主题")
  }
}

private struct SearchField: View {
  @Binding var text: String

  var body: some View {
    HStack(spacing: 9) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(StudioColors.muted)
      TextField("搜索名称、风格或颜色", text: $text)
        .textFieldStyle(.plain)
        .foregroundStyle(StudioColors.text)
      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(StudioColors.muted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("清除搜索")
      }
    }
    .padding(.horizontal, 12)
    .frame(width: 250, height: 34)
    .background(StudioColors.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(StudioColors.line, lineWidth: 1)
    )
  }
}

private struct ErrorPanel: View {
  @EnvironmentObject private var controller: SkinController
  let error: String

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(StudioColors.amber)
      VStack(alignment: .leading, spacing: 5) {
        Text("操作未完成")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(StudioColors.text)
        Text(error)
          .font(.system(size: 10))
          .foregroundStyle(StudioColors.muted)
          .textSelection(.enabled)
      }
      Spacer()
      Button("修复") { controller.repair() }
        .buttonStyle(StudioSecondaryButtonStyle())
    }
    .padding(12)
    .background(StudioColors.amber.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(StudioColors.amber.opacity(0.18), lineWidth: 1)
    )
  }
}

struct SettingsView: View {
  @EnvironmentObject private var controller: SkinController
  @State private var searchText = ""
  @State private var selectedCategory = ThemeCategory.all

  private let columns = [
    GridItem(.adaptive(minimum: 215, maximum: 280), spacing: 14),
  ]

  private var filteredThemes: [ThemeDescriptor] {
    controller.themes.filter { theme in
      let categoryMatches = selectedCategory == .all || theme.category == selectedCategory
      return categoryMatches && theme.matches(searchText)
    }
  }

  private var visibleCategories: [ThemeCategory] {
    [.all, .solid, .abstract, .character, .custom]
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        StatusHeader()

        HStack(alignment: .top, spacing: 16) {
          ThemeHero(theme: controller.selectedTheme)
            .frame(maxWidth: .infinity)
          AutomationPanel()
            .frame(width: 276)
        }

        if let error = controller.lastError {
          ErrorPanel(error: error)
        }

        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 3) {
            Text("主题库")
              .font(.system(size: 22, weight: .bold, design: .rounded))
              .foregroundStyle(StudioColors.text)
            Text("\(filteredThemes.count) 套可用主题 · 本机处理，不上传图片")
              .font(.system(size: 11))
              .foregroundStyle(StudioColors.muted)
          }
          Spacer()
          SearchField(text: $searchText)
          Button("导入图片") { controller.importBackground() }
            .buttonStyle(StudioSecondaryButtonStyle())
          Button("打开目录") { controller.openThemeFolder() }
            .buttonStyle(StudioSecondaryButtonStyle())
        }

        Picker("主题分类", selection: $selectedCategory) {
          ForEach(visibleCategories) { category in
            Text(category.label).tag(category)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 440)

        if filteredThemes.isEmpty {
          StudioPanel {
            VStack(spacing: 10) {
              Image(systemName: "rectangle.stack.badge.questionmark")
                .font(.system(size: 28))
                .foregroundStyle(StudioColors.muted)
              Text("没有找到匹配的主题")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(StudioColors.text)
              Text("换个关键词，或导入一张背景图创建自定义主题。")
                .font(.system(size: 11))
                .foregroundStyle(StudioColors.muted)
              Button("清除筛选") {
                searchText = ""
                selectedCategory = .all
              }
              .buttonStyle(StudioSecondaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .padding(42)
          }
        } else {
          LazyVGrid(columns: columns, spacing: 14) {
            ForEach(filteredThemes) { theme in
              ThemeCard(theme: theme)
            }
          }
        }

        HStack(spacing: 9) {
          Button("刷新状态") { controller.refreshNow() }
          Button("修复并重新应用") { controller.repair() }
          Button("打开日志") { controller.openLogsFolder() }
          Spacer()
          Text("CDP 仅绑定 127.0.0.1 · 不修改官方 App")
            .font(.system(size: 10))
            .foregroundStyle(StudioColors.muted)
        }
        .buttonStyle(StudioSecondaryButtonStyle())
        .disabled(controller.isBusy)
      }
      .padding(26)
    }
    .frame(minWidth: 860, minHeight: 680)
    .studioWindowBackground()
    .preferredColorScheme(.dark)
  }
}
