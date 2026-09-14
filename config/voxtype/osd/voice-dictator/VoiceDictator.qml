import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string daemonState: "idle"
    property var audio: null
    property var theme: null
    property var recipe: null
    property string assetRoot: ""

    property real peak: 0.0
    property real rms: 0.0
    property real vadLevel: 0.0
    property real smoothPeak: 0.0
    property real smoothRms: 0.0
    property real phase: 0.0
    property real lastTickMs: Date.now()
    property real appear: 1.0
    property string priorState: "idle"
    property var samples: []

    readonly property bool active: daemonState === "recording"
        || daemonState === "streaming"
        || daemonState === "transcribing"

    function _configValue(key, fallback) {
        return theme && theme.config && theme.config[key] !== undefined
            ? theme.config[key]
            : fallback;
    }

    function _color(role, fallback) {
        if (theme && theme.color)
            return theme.color(role, fallback);
        return fallback;
    }

    function _stateColor() {
        if (daemonState === "streaming")
            return _color("streaming", "#6EA8FF");
        if (daemonState === "transcribing")
            return _color("transcribing", "#FFC857");
        if (daemonState === "recording")
            return _color("recording", "#4CC9FF");
        return _color("idle", "rgba(140, 214, 235, 0.55)");
    }

    function _stateLabel() {
        if (daemonState === "streaming")
            return "STREAMING";
        if (daemonState === "transcribing")
            return "PROCESSING";
        if (daemonState === "recording")
            return vadLevel > 0.45 ? "LISTENING" : "STANDBY";
        return "IDLE";
    }

    function _clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }

    function _approach(current, target, stiffness, dt) {
        const amount = 1.0 - Math.exp(-Math.max(0.01, stiffness) * dt);
        return current + (target - current) * amount;
    }

    function _hudSize() {
        return Math.min(188, Math.max(132, Math.min(root.width, root.height) * 0.16));
    }

    function _hudX(size) {
        const position = String(_configValue("position", "bottom-center"));
        const margin = Math.max(0, Number(_configValue("margin_px", 24)));
        if (position.indexOf("left") >= 0)
            return margin;
        if (position.indexOf("right") >= 0)
            return Math.max(margin, root.width - size - margin);
        return Math.max(margin, (root.width - size) / 2);
    }

    function _hudY(size) {
        const position = String(_configValue("position", "bottom-center"));
        const margin = Math.max(0, Number(_configValue("margin_px", 24)));
        const labelRoom = Math.round(size * 0.30);
        if (position === "top-left" || position === "top-right" || position === "top-center")
            return margin;
        if (position.indexOf("bottom") >= 0) {
            const dockClearance = 88;
            return Math.max(margin, root.height - size - margin - labelRoom - dockClearance);
        }
        const topMargin = _clamp(Number(_configValue("top_margin", 0.78)), 0.0, 1.0);
        return Math.max(margin, Math.min(root.height - size - margin - labelRoom, root.height * topMargin));
    }

    function _sample(index, count) {
        const r = samples || [];
        if (r.length > 1) {
            const pos = index * (r.length - 1) / Math.max(1, count - 1);
            const lo = Math.floor(pos);
            const hi = Math.min(r.length - 1, lo + 1);
            return r[lo] * (1 - (pos - lo)) + r[hi] * (pos - lo);
        }
        return 0.012 + 0.01 * Math.sin(phase * 1.1 + index * 0.41);
    }

    function _withAlpha(color, alpha) {
        const str = String(color);
        if (str[0] === "#" && str.length === 7) {
            const r = parseInt(str.slice(1, 3), 16);
            const g = parseInt(str.slice(3, 5), 16);
            const b = parseInt(str.slice(5, 7), 16);
            return "rgba(" + r + ", " + g + ", " + b + ", " + alpha + ")";
        }
        if (str[0] === "#" && str.length === 9) {
            const r = parseInt(str.slice(3, 5), 16);
            const g = parseInt(str.slice(5, 7), 16);
            const b = parseInt(str.slice(7, 9), 16);
            return "rgba(" + r + ", " + g + ", " + b + ", " + alpha + ")";
        }
        const m = /^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)/.exec(str);
        if (m)
            return "rgba(" + m[1] + ", " + m[2] + ", " + m[3] + ", " + alpha + ")";
        return color;
    }

    function _playIntro() {
        appear = 0;
        introAnim.restart();
    }

    FileView {
        path: {
            const xdg = Quickshell.env("XDG_RUNTIME_DIR");
            if (xdg && xdg.length > 0)
                return xdg + "/voxtype/state";
            return "/run/user/1000/voxtype/state";
        }
        watchChanges: true
        printErrors: false
        onLoaded: {
            const next = (text() || "idle").trim();
            if (next.length > 0 && next !== root.daemonState)
                root.daemonState = next;
        }
        onFileChanged: reload()
    }

    Connections {
        target: root.audio
        enabled: root.audio !== null

        function onFrameReceived(framePeak, frameRms, vad) {
            root.peak = root._clamp(framePeak, 0.0, 1.0);
            root.rms = root._clamp(frameRms, 0.0, 1.0);
            root.vadLevel = vad ? 1.0 : 0.0;
            const next = root.samples.slice();
            next.push(root.peak);
            while (next.length > 72)
                next.shift();
            root.samples = next;
        }

        function onDisconnected() {
            root.peak = 0.0;
            root.rms = 0.0;
            root.vadLevel = 0.0;
            root.samples = [];
        }
    }

    onDaemonStateChanged: {
        const wasActive = priorState === "recording"
            || priorState === "streaming"
            || priorState === "transcribing";
        priorState = daemonState;
        if (!root.active) {
            peak = 0.0;
            rms = 0.0;
            vadLevel = 0.0;
            samples = [];
        } else if (!wasActive) {
            _playIntro();
        }
        hud.requestPaint();
    }

    onVisibleChanged: {
        if (visible && root.active)
            _playIntro();
    }

    NumberAnimation {
        id: introAnim
        target: root
        property: "appear"
        from: 0
        to: 1
        duration: 420
        easing.type: Easing.OutCubic
    }

    Timer {
        interval: 16
        repeat: true
        running: root.visible && root.active
        triggeredOnStart: true
        onTriggered: {
            const now = Date.now();
            const dt = Math.min(0.05, Math.max(0.001, (now - root.lastTickMs) / 1000.0));
            root.lastTickMs = now;
            root.phase += dt;
            root.smoothPeak = root._approach(root.smoothPeak, root.peak, 16.0, dt);
            root.smoothRms = root._approach(root.smoothRms, root.rms, 11.0, dt);
            root.vadLevel = root._approach(root.vadLevel, root.audio && root.audio.vad ? 1.0 : 0.0, 10.0, dt);
            hud.requestPaint();
        }
    }

    Canvas {
        id: hud
        anchors.fill: parent
        antialiasing: false
        opacity: root.active ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        function _bayer(x, y) {
            const xx = x % 8;
            const yy = y % 8;
            const index =
                1.0 * (xx % 2) +
                2.0 * (yy % 2) +
                4.0 * (Math.floor(xx / 2) % 2) +
                8.0 * (Math.floor(yy / 2) % 2) +
                16.0 * (Math.floor(xx / 4) % 2) +
                32.0 * (Math.floor(yy / 4) % 2);
            return (index + 0.5) / 64.0;
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.active)
                return;

            const size = root._hudSize();
            const x0 = root._hudX(size);
            const y0 = root._hudY(size);
            const cx = x0 + size / 2;
            const cy = y0 + size / 2;
            const accent = root._color("accent", "#F4F1EA");
            const fg = root._color("foreground", "#FFFFFF");
            const amplitude = root._clamp(root.smoothPeak * 0.9 + root.smoothRms * 1.55 + root.vadLevel * 0.18, 0.06, 1.15);
            const time = root.phase;
            const cell = 2;
            const rMax = size / 2;
            const radius = (0.21 + amplitude * 0.11 + Math.sin(time * 0.9) * 0.012) * size;
            const thickness = (0.07 + amplitude * 0.05 + Math.sin(time * 0.63) * 0.009) * size;
            const pop = 0.78 + Math.min(1.0, Math.max(0.0, root.appear)) * 0.22;

            ctx.save();
            ctx.translate(cx, cy);
            ctx.scale(pop, pop);
            ctx.translate(-cx, -cy);

            ctx.fillStyle = "#ffffff";
            for (let py = 0; py < size; py += cell) {
                for (let px = 0; px < size; px += cell) {
                    const dx = (px + 0.5) - size / 2;
                    const dy = (py + 0.5) - size / 2;
                    const dist = Math.sqrt(dx * dx + dy * dy);
                    const ring = _smooth(radius + thickness, radius, dist) - _smooth(radius, radius - thickness, dist);
                    const glow = Math.exp(-14.0 * Math.abs(dist - radius));
                    const halo = Math.exp(-6.5 * (dist / rMax) * (1.0 + amplitude * 0.35));
                    const intensity = Math.max(0.0, Math.min(1.0, ring * 0.75 + glow * 0.5 + halo * 0.08));
                    if (intensity <= _bayer(px / cell, py / cell))
                        continue;
                    ctx.fillRect(x0 + px, y0 + py, cell, cell);
                }
            }

            const core = 6 + amplitude * 10;
            ctx.beginPath();
            ctx.fillStyle = "rgba(255,255,255," + (0.55 + amplitude * 0.4).toFixed(3) + ")";
            ctx.arc(cx, cy, core, 0, Math.PI * 2);
            ctx.fill();

            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.font = "500 " + Math.max(11, Math.round(size * 0.08)) + "px Rubik, sans-serif";
            ctx.fillStyle = fg;
            ctx.globalAlpha = 0.72 + amplitude * 0.2;
            ctx.fillText(root._stateLabel(), cx, cy + rMax * 1.08);
            ctx.restore();
        }

        function _smooth(edge0, edge1, x) {
            const t = Math.max(0.0, Math.min(1.0, (x - edge0) / (edge1 - edge0)));
            return t * t * (3.0 - 2.0 * t);
        }
    }
}
