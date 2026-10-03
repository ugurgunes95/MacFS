import Cocoa
import os.log

let log = OSLog(subsystem: "local.macfs", category: "agent")
let skipURL = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support/MacFS/skip.txt")
let settingsURL = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support/MacFS/settings.txt")

func setting(_ key: String, default def: Bool = true) -> Bool {
    let raw = (try? String(contentsOf: settingsURL, encoding: .utf8)) ?? ""
    for line in raw.split(separator: "\n") {
        let kv = line.split(separator: "=").map(String.init)
        if kv.count == 2 && kv[0] == key { return kv[1] == "1" }
    }
    return def
}

func setSetting(_ key: String, _ value: Bool) {
    var lines = ((try? String(contentsOf: settingsURL, encoding: .utf8)) ?? "")
        .split(separator: "\n").map(String.init).filter { !$0.hasPrefix(key + "=") }
    lines.append("\(key)=\(value ? 1 : 0)")
    try? lines.joined(separator: "\n").write(to: settingsURL, atomically: true, encoding: .utf8)
}

func skipped(_ bundleID: String?) -> Bool {
    guard let bundleID else { return true }
    let raw = (try? String(contentsOf: skipURL, encoding: .utf8)) ?? "com.apple.finder\n"
    return raw.split(separator: "\n").contains { $0.trimmingCharacters(in: .whitespaces) == bundleID }
}

func standardWindows(of axApp: AXUIElement) -> [AXUIElement] {
    var value: AnyObject?
    guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &value) == .success,
          let windows = value as? [AXUIElement] else { return [] }
    return windows.filter { win in
        var sub: AnyObject?
        AXUIElementCopyAttributeValue(win, kAXSubroleAttribute as CFString, &sub)
        return (sub as? String) == "AXStandardWindow"
    }
}

// MARK: - req 1: fullscreen at launch (never again after)

func fullscreen(_ app: NSRunningApplication, attempt: Int = 0) {
    guard setting("fullscreen"), !skipped(app.bundleIdentifier), !app.isTerminated else { return }
    let axApp = AXUIElementCreateApplication(app.processIdentifier)
    let windows = standardWindows(of: axApp)
    if windows.isEmpty {
        if attempt < 10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { fullscreen(app, attempt: attempt + 1) }
        }
        return
    }
    var anySet = false
    for win in windows where AXUIElementSetAttributeValue(win, "AXFullScreen" as CFString, kCFBooleanTrue) == .success {
        anySet = true
    }
    if anySet {
        os_log("fullscreened %{public}@", log: log, app.bundleIdentifier ?? "?")
    } else if app.isActive {
        // fallback: app ignores AXFullScreen, send ⌃⌘F once
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: 0x03, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: 0x03, keyDown: false)
        down?.flags = [.maskControl, .maskCommand]
        up?.flags = [.maskControl, .maskCommand]
        down?.postToPid(app.processIdentifier)
        up?.postToPid(app.processIdentifier)
        os_log("fullscreened %{public}@ via keystroke", log: log, app.bundleIdentifier ?? "?")
    }
}

// MARK: - menu bar UI

final class MenuController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    override init() {
        super.init()
        item.button?.title = "⛶"
        rebuild()
    }

    func rebuild() {
        let menu = NSMenu()
        menu.addItem(toggleItem("Auto-fullscreen at launch", "fullscreen", #selector(toggleFullscreen)))
        menu.addItem(.separator())
        menu.addItem(actionItem("Skip frontmost app", #selector(skipFrontmost)))
        menu.addItem(actionItem("Open skip list…", #selector(openSkipList)))
        menu.addItem(.separator())
        menu.addItem(actionItem("Quit MacFS", #selector(quitAgent)))
        item.menu = menu
    }

    private func toggleItem(_ title: String, _ key: String, _ action: Selector) -> NSMenuItem {
        let mi = actionItem(title, action)
        mi.state = setting(key) ? .on : .off
        return mi
    }

    private func actionItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: "")
        mi.target = self
        return mi
    }

    @objc private func toggleFullscreen() { setSetting("fullscreen", !setting("fullscreen")); rebuild() }

    @objc private func skipFrontmost() {
        guard let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier, !skipped(id) else { return }
        let raw = ((try? String(contentsOf: skipURL, encoding: .utf8)) ?? "com.apple.finder")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        try? (raw + "\n" + id + "\n").write(to: skipURL, atomically: true, encoding: .utf8)
        os_log("skipped %{public}@", log: log, id)
    }

    @objc private func openSkipList() { NSWorkspace.shared.open(skipURL) }
    @objc private func quitAgent() { NSApplication.shared.terminate(nil) }
}

// MARK: - main

if CommandLine.arguments.contains("--check") {
    print("accessibility trusted: \(AXIsProcessTrusted())")
    print("skip list: \(skipURL.path)")
    print((try? String(contentsOf: skipURL, encoding: .utf8)) ?? "(missing, defaults to com.apple.finder)")
    exit(0)
}

if !AXIsProcessTrusted() {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(opts)
    os_log("accessibility not granted yet; prompted user", log: log)
}

let nc = NSWorkspace.shared.notificationCenter
nc.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { note in
    guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
    fullscreen(app)
}

os_log("macfs started", log: log)
let menu = MenuController()
NSApplication.shared.setActivationPolicy(.accessory)
NSApplication.shared.run()
