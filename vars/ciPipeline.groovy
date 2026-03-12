def call(Map cfg = [:]) {
    boolean enableDeploy = (cfg.enableDeploy == true)

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
                        env.JENKINS_RUNTIME_ENV = ctx.runtimeEnv ?: ""
                        env.MANUAL_PROD_DEPLOY = (cfg.enableDeploy == true).toString()

                        echo "Environment: env=${env.PIPELINE_ENV}, runtimeEnv=${env.JENKINS_RUNTIME_ENV}, isPR=${env.IS_PR}, branch=${env.BRANCH_NAME}, manualProdDeploy=${env.MANUAL_PROD_DEPLOY}"
                    }
                }
            }

            stage('Validate Config') {
                steps {
                    script {
                        if (cfg.containsKey('pipelineEnv') || cfg.containsKey('runtimeEnv') || cfg.containsKey('environment')) {
                            error("pipeline environment is resolved from context and must not be passed to ciPipeline")
                        }
                        if (!cfg.dockerRepo) {
                            error("dockerRepo is required")
                        }
                        if (!cfg.localImageName) {
                            error("localImageName is required")
                        }
                        if (env.PIPELINE_ENV == 'prod' && env.MANUAL_PROD_DEPLOY == 'true' && !cfg.deployRepo) {
                            error("deployRepo is required for prod deployment")
                        }
                        if (env.PIPELINE_ENV in ['dev', 'staging'] && !cfg.deployRepo) {
                            error("deployRepo is required for deployment environments")
                        }
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
                        def imageMeta = buildImage(cfg)
                        env.IMAGE_TAG = imageMeta.immutableTag
                        env.MUTABLE_TAG = imageMeta.mutableTag ?: ""
                        env.IMAGE_URI = imageMeta.imageUri
                        env.VERSION_TAG = imageMeta.versionTag ?: ""
                        echo "Built image: ${env.IMAGE_URI}"
                    }
                }
            }

            stage('Container Push') {
                when {
                    expression { env.PIPELINE_ENV in ['dev', 'staging', 'prod'] }
                }
                steps {
                    script {
                        pushImage(cfg + [
                            dockerRepo : cfg.dockerRepo,
                            imageUri   : env.IMAGE_URI,
                            imageTag   : env.IMAGE_TAG,
                            mutableTag : env.MUTABLE_TAG,
                            versionTag : env.VERSION_TAG
                        ])
                    }
                }
            }

            stage('Prod Approval') {
                when {
                    expression {
                        env.PIPELINE_ENV == 'prod' && env.MANUAL_PROD_DEPLOY == 'true'
                    }
                }
                steps {
                    script {
                        requireProdApproval()
                    }
                }
            }

            stage('Deploy') {
                when {
                    expression {
                        return (
                            env.PIPELINE_ENV == 'dev' ||
                            env.PIPELINE_ENV == 'staging' ||
                            (env.PIPELINE_ENV == 'prod' && env.MANUAL_PROD_DEPLOY == 'true')
                        )
                    }
                }
                steps {
                    script {
                        deployCompose(cfg + [
                            deployRepo : cfg.deployRepo,
                            imageUri   : env.IMAGE_URI,
                            imageTag   : env.IMAGE_TAG,
                            mutableTag : env.MUTABLE_TAG,
                            versionTag : env.VERSION_TAG
                        ])
                    }
                }
            }
        }
    }
}
