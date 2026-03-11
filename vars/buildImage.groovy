def call(Map cfg = [:]) {
    String dockerRepo  = cfg.dockerRepo ?: error("dockerRepo is required")
    String localImageName = cfg.localImageName ?: error("localImageName is required")
    String imageBuildCmd = cfg.imageBuildCmd ?: "make build"
    String pipelineEnv = cfg.pipelineEnv ?: "build"
    String version = (cfg.version ?: env.VERSION ?: "").trim()

    String shortSha = (env.GIT_COMMIT ?: "unknown").take(7)
    String immutableTag = "${pipelineEnv}-${env.BUILD_NUMBER}-git-${shortSha}"
    String imageUri = "${dockerRepo}:${immutableTag}"
    String versionTag = ""

    sh imageBuildCmd
    sh "docker tag ${localImageName} ${imageUri}"

    if (pipelineEnv != "build") {
        sh "docker tag ${imageUri} ${dockerRepo}:${pipelineEnv}-latest"
    }
    if (pipelineEnv == "prod" && version) {
        versionTag = "v${version}"
        sh "docker tag ${imageUri} ${dockerRepo}:${versionTag}"
    }

    return [
        immutableTag: immutableTag,
        imageUri: imageUri,
        versionTag: versionTag
    ]
}
