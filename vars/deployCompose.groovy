def call(Map cfg = [:]) {
    dir('central-deploy-repo') {
        checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: cfg.deployRepo]]])
        
        withEnv(["IMAGE_URI=${cfg.imageUri}", "IMAGE_TAG=${cfg.imageTag}", "ENV=${cfg.pipelineEnv}"]) {
            sh "./scripts/deploy-${cfg.pipelineEnv}.sh"
        }
    }
}