import Foundation

class LogRateLimiter {
    private let maxLogsCount: Int = 5000
    private let timeDuration: TimeInterval = 5.0
    private var logCount: Int = 0
    private var startTime: Date = Date()
    private let queue = DispatchQueue(label: "clashx.logratelimiter", qos: .utility)
    private var isBlocked = false
    
    private let onRateLimitTriggered: () -> Void
    
    init(onRateLimitTriggered: @escaping () -> Void) {
        self.onRateLimitTriggered = onRateLimitTriggered
    }
    
    // Returns true if log can be processed, false if rate limited
    func processLog() -> Bool {
        return queue.sync { [weak self] in
            guard let self = self, !self.isBlocked else { return false }
            
            let now = Date()
            
            // Reset counter if more than 5 seconds passed
            if now.timeIntervalSince(self.startTime) >= self.timeDuration {
                self.startTime = now
                self.logCount = 0
            }
            
            // Check if rate limit exceeded
            if self.logCount >= self.maxLogsCount {
                self.triggerRateLimit()
                return false
            }
            
            self.logCount += 1
            return true
        }
    }
    
    private func triggerRateLimit() {
        isBlocked = true
        
        DispatchQueue.main.async { [weak self] in
            self?.onRateLimitTriggered()
            Logger.log("⚠️ Rate limit triggered: >5000 logs/5sec, paused for 1min")
        }
        
        // Resume after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) { [weak self] in
            self?.isBlocked = false
            Logger.log("✅ Rate limit resumed")
        }
    }
}
