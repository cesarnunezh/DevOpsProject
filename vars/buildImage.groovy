def call(Map cfg = [:]) {
    String dockerRepo  = cfg.dockerRepo ?: error("dockerRepo is required")
    String localImageName = cfg.localImageName ?: error("localImageName is required")
    String imageBuildCmd = cfg.imageBuildCmd ?: "make build"
    String pipelineEnv = cfg.pipelineEnv ?: "build"

    String shortSha = (env.GIT_COMMIT ?: "unknown").take(7)
    String immutableTag = "${pipelineEnv}-${env.BUILD_NUMBER}-git-${shortSha}"
    String imageUri = "${dockerRepo}:${immutableTag}"

    sh imageBuildCmd
    sh "docker tag ${localImageName} ${imageUri}"

    if (pipelineEnv != "build") {
        sh "docker tag ${imageUri} ${dockerRepo}:${pipelineEnv}-latest"
    }

    return [
        immutableTag: immutableTag,
        imageUri: imageUri
    ]
}
