import Foundation

#if canImport(MetricKit) && os(iOS)
    import MetricKit

    final class MetricKitTelemetrySubscriber: NSObject, MXMetricManagerSubscriber {
        private var isStarted = false

        func start() {
            guard !isStarted else { return }
            MXMetricManager.shared.add(self)
            isStarted = true
            PerformanceTelemetry.notice("MetricKit subscriber started", category: .performance)
        }

        func stop() {
            guard isStarted else { return }
            MXMetricManager.shared.remove(self)
            isStarted = false
        }

        deinit {
            stop()
        }

        func didReceive(_ payloads: [MXMetricPayload]) {
            PerformanceTelemetry.notice(
                "MetricKit metric payloads received: \(payloads.count)", category: .performance)
        }

        func didReceive(_ payloads: [MXDiagnosticPayload]) {
            PerformanceTelemetry.notice(
                "MetricKit diagnostic payloads received: \(payloads.count)", category: .performance)
        }
    }
#else
    final class MetricKitTelemetrySubscriber {
        func start() {}
        func stop() {}
    }
#endif
