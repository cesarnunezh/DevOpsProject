def call(Map cfg = [:]) {
    Map versionConfig = loadVersionConfig()
    String mutableTagSuffix = (versionConfig.cicd?.mutable_tag_suffix ?: "latest").trim()
    String pipelineEnv = (env.PIPELINE_ENV ?: "").trim()
    String mutableTag = (cfg.mutableTag ?: (pipelineEnv ? "${pipelineEnv}-${mutableTagSuffix}" : "")).trim()

    withCredentials([usernamePassword(
        credentialsId: 'final_project',
        usernameVariable: 'DOCKER_USER',
        passwordVariable: 'DOCKER_PASS'
    )]) {
        withEnv(["DOCKER_CONFIG=${env.WORKSPACE}/.docker-tmp"]) {
            sh 'mkdir -p "$DOCKER_CONFIG"'
            sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'

            try {
                sh "docker push ${cfg.imageUri}"
                if (mutableTag) {
                    sh "docker push ${cfg.dockerRepo}:${mutableTag}"
                }
                if (cfg.versionTag?.trim()) {
                    sh "docker push ${cfg.dockerRepo}:${cfg.versionTag}"
                }
            } finally {
                sh 'docker logout || true'
                sh 'rm -rf "$DOCKER_CONFIG"'
            }
        }
    }
}
