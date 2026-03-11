import groovy.json.JsonSlurperClassic

def call() {
    String path = 'config/versions.json'

    if (!fileExists(path)) {
        echo "config/versions.json not found. Using default configuration."
        return [:]
    }

    String rawConfig = readFile(file: path)
    return new JsonSlurperClassic().parseText(rawConfig) as Map
}