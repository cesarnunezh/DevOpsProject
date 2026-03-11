import groovy.json.JsonSlurperClassic

def call() {
    String rawConfig = readFile(file: 'config/versions.json')
    return new JsonSlurperClassic().parseText(rawConfig) as Map
}
