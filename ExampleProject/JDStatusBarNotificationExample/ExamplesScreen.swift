//
//

import Foundation
import SwiftUI

@available(iOS 15.0, *)
class ExamplesScreenFactory: NSObject {
  @objc static func createExamplesScreen() -> UIViewController {
    let text = "👋 Hello World!"
    NotificationPresenter.shared().present(text: text,
                                           dismissAfterDelay: 2.5,
                                           includedStyle: IncludedStatusBarStyle.matrix)
    return UIHostingController(rootView:
      NavigationView {
        ExamplesScreen()
      }
    )
  }
}

@available(iOS 15.0, *)
struct ExamplesScreen: View {
  @State var progress = 0.0
  @State var showActivity = false
  @State var showSubtitle = false
  @State var backgroundType: BarBackgroundType = .pill

  func showDefaultNotification(_ text: String, completion: @escaping (NotificationPresenter) -> ()) {
    let styleName = NotificationPresenter.shared().addStyle(styleName: "tmp", basedOnIncludedStyle: .defaultStyle) { style in
      style.backgroundStyle.backgroundType = backgroundType
      return style
    }
    NotificationPresenter.shared().present(title: text,
                                           subtitle: showSubtitle ? "{subtitle}" : nil,
                                           customStyle: styleName,
                                           completion: completion)

    if showActivity {
      NotificationPresenter.shared().displayActivityIndicator(true)
    }
    if progress > 0.0 {
      NotificationPresenter.shared().displayProgressBar(percentage: progress)
    }
  }

  func showIncludedStyle(_ text: String, style: IncludedStatusBarStyle) {
    let styleName = NotificationPresenter.shared().addStyle(styleName: "tmp", basedOnIncludedStyle: style) { style in
      style.backgroundStyle.backgroundType = backgroundType
      return style
    }
    NotificationPresenter.shared().present(title: text,
                                           subtitle: showSubtitle ? "{subtitle}" : nil,
                                           customStyle: styleName)
    NotificationPresenter.shared().dismiss(afterDelay: 3.0)

    if showActivity {
      NotificationPresenter.shared().displayActivityIndicator(true)
    }
    if progress > 0.0 {
      NotificationPresenter.shared().displayProgressBar(percentage: progress)
    }
  }

  var body: some View {
    List {
      Section {
        NavigationLink {
          StyleEditorScreen()
        } label: {
          VStack(alignment: .leading) {
            Text("Style Editor")
              .font(.subheadline)
              .foregroundColor(.accentColor)
            Text("Get creative & create your own style!")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }.foregroundColor(.accentColor)
      }

      Section("Default Style") {
        cell(title: "Present / dismiss", subtitle: "Default style, don't autohide", useAccentColor: true) {
          if NotificationPresenter.shared().isVisible() {
            NotificationPresenter.shared().dismiss()
          } else {
            showDefaultNotification("Better call Saul!") { _ in }
          }
        }
        cell(title: "Animate progress bar & hide", subtitle: "Hide bar at 100%", useAccentColor: true) {
          if !NotificationPresenter.shared().isVisible() {
            showDefaultNotification("Animating Progress…") { presenter in
              presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
                presenter.dismiss()
              }
            }
            NotificationPresenter.shared().displayProgressBar(percentage: 0.0)
          } else {
            NotificationPresenter.shared().displayProgressBar(percentage: 0.0)
            NotificationPresenter.shared().animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }
      }

      Section("Settings") {
        Toggle("Show subtitle", isOn: $showSubtitle)
          .onChange(of: showSubtitle) { on in
            if on, !NotificationPresenter.shared().isVisible() {
              showDefaultNotification("Look!") { _ in }
              NotificationPresenter.shared().dismiss(afterDelay: 2.0)
            }
            NotificationPresenter.shared().updateSubtitle(on ? "I am a subtitle" : nil)
          }.font(.subheadline)

        Toggle("Activity Indicator", isOn: $showActivity)
          .onChange(of: showActivity) { _ in
            if !NotificationPresenter.shared().isVisible() {
              if showActivity {
                let styleName = NotificationPresenter.shared().addStyle(styleName: "tmp", basedOnIncludedStyle: .defaultStyle) { style in
                  style.backgroundStyle.backgroundType = backgroundType
                  style.backgroundStyle.pillStyle.minimumWidth = 0.0
                  return style
                }
                NotificationPresenter.shared().present(text: "", dismissAfterDelay: 2.0, customStyle: styleName)
                NotificationPresenter.shared().displayActivityIndicator(true)
              }
            } else {
              NotificationPresenter.shared().displayActivityIndicator(showActivity)
            }
          }.font(.subheadline)

        HStack {
          Text("Progress Bar (\(Int(round(progress * 100)))%)")
          Spacer()
          Slider(value: $progress)
            .frame(width: 150)
        }
        .onChange(of: progress) { _ in
          if !NotificationPresenter.shared().isVisible() {
            if progress > 0.0 {
              showDefaultNotification("Making progress…") { _ in }
              NotificationPresenter.shared().dismiss(afterDelay: 2.0)
            }
          } else {
            NotificationPresenter.shared().displayProgressBar(percentage: progress)
          }
        }.font(.subheadline)

        VStack(alignment: .leading, spacing: 6.0) {
          Text("BarBackgroundType").font(.subheadline)
          Picker("", selection: $backgroundType) {
            EnumPickerOptionView(BarBackgroundType.pill)
            EnumPickerOptionView(BarBackgroundType.fullWidth)
          }.font(.subheadline).pickerStyle(.segmented)
        }
        .onChange(of: backgroundType) { _ in
          showDefaultNotification(backgroundType == .pill ? "Ohhh so shiny!" : "I prefer classic…") { _ in }
          NotificationPresenter.shared().dismiss(afterDelay: 2.0)
        }
      }

      Section("Included Styles") {
        includedStyleCell("Uh huh.", style: .defaultStyle)
        includedStyleCell("It's time.", style: .light)
        includedStyleCell("Don't mess with me!", style: .dark)
        includedStyleCell("That's how we roll!", style: .success)
        includedStyleCell("You know who I am!", style: .warning)
        includedStyleCell("Uh oh, that didn't work..", style: .error)
        includedStyleCell("Wake up Neo…", style: .matrix)
      }

      Section("Custom Styles") {
        cell(title: "Love it!", subtitle: "AnimationType.fade + Progress") {
          ExampleStyle.registerStyles(for: backgroundType)
          NotificationPresenter.shared().present(text: "Love it!",
                                                 customStyle: ExampleStyle.loveIt.rawValue) { presenter in
            presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }

        cell(title: "Level Up", subtitle: "AnimationType.bounce + Progress") {
          ExampleStyle.registerStyles(for: backgroundType)
          NotificationPresenter.shared().present(text: "Level up!",
                                                 customStyle: ExampleStyle.levelUp.rawValue) { presenter in
            presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }

        cell(title: "Looks good", subtitle: "Subtitle + Activity") {
          ExampleStyle.registerStyles(for: backgroundType)
          NotificationPresenter.shared().present(title: "Presenting",
                                                 subtitle: "This is looking good",
                                                 customStyle: ExampleStyle.looksGood.rawValue)
          NotificationPresenter.shared().displayActivityIndicator(true)
          NotificationPresenter.shared().dismiss(afterDelay: 2.0)
        }

        cell(title: "Small Pill", subtitle: "Modified pill size + Progress") {
          ExampleStyle.registerStyles(for: backgroundType)
          NotificationPresenter.shared().present(text: "Oh, hello there!", customStyle: ExampleStyle.smallPill.rawValue) { presenter in
            presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }

        cell(title: "Style Editor Style", subtitle: "Subtitle + Progress") {
          ExampleStyle.registerStyles(for: backgroundType)
          NotificationPresenter.shared().present(title: "Edit me", subtitle: "in the Style Editor", customStyle: ExampleStyle.editor.rawValue) { presenter in
            presenter.animateProgressBar(toPercentage: 1.0, animationDuration: animationDurationForCurrentStyle()) { presenter in
              presenter.dismiss()
            }
          }
        }

        cell(title: "2 notifications in sequence", subtitle: "Utilizing the completion block") {
          showIncludedStyle("This is 1/2!", style: .dark)
          NotificationPresenter.shared().displayActivityIndicator(true)
          NotificationPresenter.shared().displayProgressBar(percentage: 0.0)
          NotificationPresenter.shared().dismiss(afterDelay: 1.0) { presenter in
            showIncludedStyle("✅ This is 2/2!", style: .dark)
            NotificationPresenter.shared().displayActivityIndicator(false)
            NotificationPresenter.shared().displayProgressBar(percentage: 0.0)
            presenter.dismiss(afterDelay: 1.0)
          }
        }
      }

      Section("Custom Views") {
        cell(title: "Present a button", subtitle: "A custom notification view") {
          // create button
          let button = UIButton(type: .system, primaryAction: UIAction { _ in
            NotificationPresenter.shared().dismiss()
          })
          button.setTitle("Dismiss!", for: .normal)

          // present
          let styleName = NotificationPresenter.shared().addStyle(styleName: "tmp", basedOnIncludedStyle: .defaultStyle) { style in
            style.backgroundStyle.backgroundType = backgroundType
            return style
          }
          NotificationPresenter.shared().present(customView: button, style: styleName)
        }

        cell(title: "Present with icon", subtitle: "A custom left view") {
          // create icon
          let image = UIImageView(image: UIImage(systemName: "gamecontroller.fill"))
          image.tintColor = UIColor.orange
          image.sizeToFit()

          // present
          ExampleStyle.registerStyles(for: backgroundType)
          NotificationPresenter.shared().present(title: "Player II", subtitle: "Connected", customStyle: ExampleStyle.iconLeftView.rawValue)
          NotificationPresenter.shared().displayLeftView(image)
          NotificationPresenter.shared().dismiss(afterDelay: 2.5)
        }
      }
    }
    .navigationTitle(Bundle.main.object(forInfoDictionaryKey: "ExampleViewControllerTitle") as? String ?? "")
    .navigationBarTitleDisplayMode(.inline)
  }

  func cell(title: String, subtitle: String? = nil, useAccentColor: Bool = false, action: @escaping () -> ()) -> some View {
    Button(action: action, label: {
      HStack {
        VStack(alignment: .leading) {
          Text(title)
            .font(.subheadline)
            .foregroundColor(useAccentColor ? .accentColor : .primary)
          if let subtitle = subtitle {
            Text(subtitle)
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
        Spacer()
        NavigationLink.empty
          .frame(width: 30.0)
          .foregroundColor(useAccentColor ? .accentColor : .secondary)
      }
    })
  }

  func includedStyleCell(_ text: String, style: IncludedStatusBarStyle) -> some View {
    cell(title: "Present \(style.stringValue)", subtitle: "Duration: 3s") {
      showIncludedStyle(text, style: style)
    }
  }

  func animationDurationForCurrentStyle() -> Double {
    switch backgroundType {
      case .pill:
        return 0.66
      case .fullWidth:
        fallthrough
      default:
        return 1.2
    }
  }
}

extension NavigationLink where Label == EmptyView, Destination == EmptyView {
  static var empty: NavigationLink {
    self.init(destination: EmptyView(), label: { EmptyView() })
  }
}

@available(iOS 15.0, *)
struct ExamplesScreen_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      ExamplesScreen()
    }
  }
}
