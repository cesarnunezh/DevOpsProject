def call(Map cfg = [:]) {
    String pipelineEnv = (env.PIPELINE_ENV ?: "").trim()
    if (!pipelineEnv) {
        error("pipeline environment could not be resolved from context")
    }

    dir('central-deploy-repo') {
        checkout([
            $class: 'GitSCM',
            branches: [[name: '*/main']],
            userRemoteConfigs: [[url: cfg.deployRepo]]
        ])

        def scriptPath = "./scripts/deploy-${pipelineEnv}.sh"

        withEnv([
            "IMAGE_URI=${cfg.imageUri}",
            "IMAGE_TAG=${cfg.imageTag}",
            "MUTABLE_TAG=${cfg.mutableTag ?: ''}",
            "VERSION_TAG=${cfg.versionTag ?: ''}",
            "ENV=${pipelineEnv}"
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
