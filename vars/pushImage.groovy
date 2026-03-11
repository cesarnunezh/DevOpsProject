def call(Map cfg = [:]) {
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
                sh "docker push ${cfg.dockerRepo}:${cfg.pipelineEnv}-latest"
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