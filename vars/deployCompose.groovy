def call(Map cfg = [:]) {
    dir('central-deploy-repo') {
        checkout([
            $class: 'GitSCM',
            branches: [[name: '*/main']],
            userRemoteConfigs: [[url: cfg.deployRepo]]
        ])

        def scriptPath = "./scripts/deploy-${cfg.pipelineEnv}.sh"

        withEnv([
            "IMAGE_URI=${cfg.imageUri}",
            "IMAGE_TAG=${cfg.imageTag}",
            "ENV=${cfg.pipelineEnv}"
        ]) {
            sh """
                set -e
                test -f ${scriptPath}
                sed -i 's/\\r\$//' ${scriptPath} || true
                chmod +x ${scriptPath}
                bash ${scriptPath}
            """
        }
    }
}