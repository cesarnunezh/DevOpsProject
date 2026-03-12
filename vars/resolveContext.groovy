def call() {
    String runtimeEnv = (env.JENKINS_RUNTIME_ENV ?: '').trim()
    String branch = env.BRANCH_NAME ?: ''
    boolean isPr = (env.CHANGE_ID?.trim())

    String targetEnv = 'build'
    if (runtimeEnv in ['dev', 'staging', 'prod']) {
        targetEnv = runtimeEnv
    } else if (!isPr) {
        if (branch == 'develop') targetEnv = 'dev'
        else if (branch.startsWith('release/')) targetEnv = 'staging'
        else if (branch == 'main') targetEnv = 'prod'
    }

    return [
        pipelineEnv  : targetEnv,
        isPr         : isPr,
        branchName   : branch,
        runtimeEnv   : runtimeEnv
    ]
}
