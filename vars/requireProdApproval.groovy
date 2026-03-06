def call() {
    timeout(time: 30, unit: 'MINUTES') {
        input message: 'Approve production deployment?', ok: 'Deploy'
    }
}