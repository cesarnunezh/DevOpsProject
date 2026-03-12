def call(Map cfg = [:]) {
    String dockerRepo = cfg.dockerRepo ?: error("dockerRepo is required")
    String localImageName = cfg.localImageName ?: error("localImageName is required")
    String imageBuildCmd = cfg.imageBuildCmd ?: "make build"
    String pipelineEnv = (env.PIPELINE_ENV ?: "build").trim()
    String version = (cfg.version ?: env.VERSION ?: "").trim()

    String mutableTagSuffix = (cfg.mutableTagSuffix ?: "latest").trim()
    String releaseTagPrefix = (cfg.releaseTagPrefix ?: "v").trim()

    String shortSha = (env.GIT_COMMIT ?: "unknown").take(7)
    String immutableTag = "${pipelineEnv}-${env.BUILD_NUMBER}-git-${shortSha}"
    String mutableTag = ""
    String imageUri = "${dockerRepo}:${immutableTag}"
    String versionTag = ""

    sh imageBuildCmd
    sh "docker tag ${localImageName} ${imageUri}"

    if (pipelineEnv != "build") {
        mutableTag = "${pipelineEnv}-${mutableTagSuffix}"
        sh "docker tag ${imageUri} ${dockerRepo}:${mutableTag}"
    }

    if (pipelineEnv == "prod" && version) {
        versionTag = "${releaseTagPrefix}${version}"
        sh "docker tag ${imageUri} ${dockerRepo}:${versionTag}"
    }

    return [
        immutableTag: immutableTag,
        mutableTag  : mutableTag,
        imageUri    : imageUri,
        versionTag  : versionTag
    ]
}
