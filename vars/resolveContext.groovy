def call() {
    String branch = env.BRANCH_NAME ?: ''
    boolean isPr = (env.CHANGE_ID?.trim())

    String targetEnv = 'build'
    if (!isPr) {
        if (branch == 'develop') targetEnv = 'dev'
        else if (branch.startsWith('release/')) targetEnv = 'staging'
        else if (branch == 'main') targetEnv = 'prod'
    }

    return [pipelineEnv: targetEnv, isPr: isPr, branchName: branch]
}
