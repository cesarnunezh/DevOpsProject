def call(Map cfg = [:]) {
    Map versionConfig = loadVersionConfig()
    String dockerRepo  = cfg.dockerRepo ?: error("dockerRepo is required")
    String localImageName = cfg.localImageName ?: error("localImageName is required")
    String imageBuildCmd = cfg.imageBuildCmd ?: "make build"
    String pipelineEnv = cfg.pipelineEnv ?: "build"
    String version = (cfg.version ?: env.VERSION ?: "").trim()
    String mutableTagSuffix = (versionConfig.cicd?.mutable_tag_suffix ?: "latest").trim()
    String releaseTagPrefix = (versionConfig.cicd?.release_tag_prefix ?: "v").trim()

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
        mutableTag: mutableTag,
        imageUri: imageUri,
        versionTag: versionTag
    ]
}
