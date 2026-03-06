def call(Map cfg = [:]) {
    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
        sh "docker push ${cfg.imageUri}"
        sh "docker push ${cfg.dockerRepo}:${cfg.pipelineEnv}-latest"
    }
}