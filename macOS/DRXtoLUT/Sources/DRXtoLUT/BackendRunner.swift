import Foundation

/// Un eveniment JSON emis de backend (o linie = un obiect). Backend-ul emite
/// coduri stabile și parametri, nu proză: textul îl localizează Swift.
struct BackendEvent {
    let raw: [String: Any]
    var type: String { raw["type"] as? String ?? "" }
    var code: String? { raw["code"] as? String }
    func string(_ key: String) -> String? { raw[key] as? String }
    func int(_ key: String) -> Int? { (raw[key] as? NSNumber)?.intValue }
    func strings(_ key: String) -> [String] { (raw[key] as? [Any])?.compactMap { $0 as? String } ?? [] }
}

enum BackendLocator {
    struct Paths { let python: URL; let backend: URL }

    /// Interpretorul și backend-ul din pachet. `DRX2LUT_PYTHON` +
    /// `DRX2LUT_BACKEND` există doar pentru teste de dezvoltare.
    static func locate() -> Paths? {
        let env = ProcessInfo.processInfo.environment
        let fm = FileManager.default
        if let py = env["DRX2LUT_PYTHON"], let be = env["DRX2LUT_BACKEND"] {
            return Paths(python: URL(fileURLWithPath: py), backend: URL(fileURLWithPath: be))
        }
        guard let res = Bundle.main.resourceURL else { return nil }
        let python = res.appendingPathComponent("python/bin/python3")
        let backend = res.appendingPathComponent("backend")
        guard fm.isExecutableFile(atPath: python.path), fm.fileExists(atPath: backend.appendingPathComponent("drx2lut/__main__.py").path) else { return nil }
        return Paths(python: python, backend: backend)
    }
}

/// Rulează o comandă a backend-ului ca proces copil; anularea = SIGTERM,
/// pe care backend-ul îl tratează (oprește randarea, șterge fișierul parțial).
final class BackendProcess {
    private let log = DiagnosticLog("backend")
    private let process = Process()

    func start(args: [String], onEvent: @escaping (BackendEvent) -> Void, onExit: @escaping (Int32) -> Void) throws {
        guard let paths = BackendLocator.locate() else { throw CocoaError(.fileNoSuchFile) }
        process.executableURL = paths.python
        // -E/-s: fără variabile PYTHON* și fără site-packages ale utilizatorului;
        // -B: fără .pyc scrise în pachetul semnat.
        process.arguments = ["-E", "-s", "-B", "-m", "drx2lut"] + args
        process.currentDirectoryURL = paths.backend
        var env = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("PYTHON") }
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        process.environment = env
        let out = Pipe(), err = Pipe()
        process.standardOutput = out
        process.standardError = err
        try process.run()
        log.info("Backend pornit: \(args.first ?? "?") (pid \(process.processIdentifier))")

        let proc = process
        DispatchQueue.global(qos: .utility).async {
            let errBox = ErrBox()
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global(qos: .utility).async {
                errBox.data = err.fileHandleForReading.readDataToEndOfFile()
                group.leave()
            }
            var buffer = Data()
            let handle = out.fileHandleForReading
            while true {
                let chunk = handle.availableData
                if chunk.isEmpty { break }
                buffer.append(chunk)
                while let nl = buffer.firstIndex(of: 10) {
                    let line = buffer[buffer.startIndex..<nl]
                    buffer.removeSubrange(buffer.startIndex...nl)
                    if let obj = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any] {
                        DispatchQueue.main.async { onEvent(BackendEvent(raw: obj)) }
                    }
                }
            }
            proc.waitUntilExit()
            group.wait()
            let errText = errBox.data
            let status = proc.terminationStatus
            DispatchQueue.main.async {
                if status != 0, status != 2, status != 3 {
                    let tail = String(decoding: errText.suffix(400), as: UTF8.self)
                    DiagnosticLog("backend").warning("Ieșire \(status): \(DiagnosticRedactor.redact(tail))")
                }
                onExit(status)
            }
        }
    }

    func cancel() {
        if process.isRunning { process.terminate() }
    }
}

private final class ErrBox { var data = Data() }
