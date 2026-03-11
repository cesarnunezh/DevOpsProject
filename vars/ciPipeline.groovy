def call(Map cfg = [:]) {
    boolean enableDeploy = (cfg.enableDeploy == true)

    if (enableDeploy && !cfg.deployRepo) {
        error("deployRepo is required when enableDeploy=true")
    }
    if (!cfg.dockerRepo) {
        error("dockerRepo is required")
    }
    if (!cfg.localImageName) {
        error("localImageName is required")
    }

    pipeline {
        agent any
        stages {
            stage('Checkout') {
                steps { 
                    checkout scm 
                    }
            }

            stage('Resolve Environment') {
                steps {
                    script {
                        def ctx = resolveContext()
                        env.PIPELINE_ENV = ctx.pipelineEnv
                        env.IS_PR = ctx.isPr.toString()
                        env.BRANCH_NAME = ctx.branchName
                        echo "Environment: env=${env.PIPELINE_ENV}, isPR=${env.IS_PR}, branch=${env.BRANCH_NAME}"
                    }
                }
            }

            stage('Build Stage') {
                steps {
                    script { 
                        runChecks(cfg) 
                    }
                }
            }

            stage('Test Stage') {
                steps {
                    sh(cfg.testCmd ?: 'make test')
                }
            }

            stage('Security Scan') {
                steps {
                    script { securityScan(cfg) } 
                }
            }

            stage('Container Build') {
                steps {
                    script {
                        def imageMeta = buildImage(cfg + [pipelineEnv: env.PIPELINE_ENV])
                        env.IMAGE_TAG = imageMeta.immutableTag
                        env.IMAGE_URI = imageMeta.imageUri
                        env.VERSION_TAG = imageMeta.versionTag ?: ""
                        echo "Built image: ${env.IMAGE_URI}"
                    }
                }
            }

            stage('Container Push') {
                when {
                    expression { return env.PIPELINE_ENV != 'build' } // skip for PR validation
                }
                steps {
                    script {
                        pushImage(cfg + [
                            dockerRepo : cfg.dockerRepo,
                            imageUri   : env.IMAGE_URI,
                            imageTag   : env.IMAGE_TAG,
                            versionTag : env.VERSION_TAG,
                            pipelineEnv: env.PIPELINE_ENV,
                        ])
                    }
                }
            }

            stage('Debug Env') {
                steps {
                    echo "BRANCH_NAME=${env.BRANCH_NAME}"
                    echo "PIPELINE_ENV=${env.PIPELINE_ENV}"
                    echo "enableDeploy=${enableDeploy}"
                }
            }

            stage('Prod Approval') {
            when {
                expression { return enableDeploy && env.PIPELINE_ENV == 'prod' }
            }
            steps {
                script { requireProdApproval() }
            }
            }

            stage('Deploy') {
                when {
                    expression { return enableDeploy && env.PIPELINE_ENV in ['dev', 'staging', 'prod'] }
                }
                steps {
                    script {
                        deployCompose(cfg + [
                            deployRepo : cfg.deployRepo,
                            pipelineEnv: env.PIPELINE_ENV,
                            imageUri   : env.IMAGE_URI,
                            imageTag   : env.IMAGE_TAG
                        ])
                    }
                }
            }
        }
    }
}
