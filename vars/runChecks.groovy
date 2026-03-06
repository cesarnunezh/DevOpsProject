def call(Map cfg = [:]) {
    sh(cfg.buildCmd ?: 'echo "No build command configured"')
    sh(cfg.lintCmd  ?: 'echo "No lint command configured"')
}