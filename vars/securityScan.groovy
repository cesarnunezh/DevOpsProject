def call(Map cfg = [:]) {
    // Replace with your preferred scanner command (Trivy/SAST)
    sh(cfg.securityCmd ?: 'echo "No security scan command configured"')
}