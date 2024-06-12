pipeline {
    agent {
        kubernetes {
            label "jenkins-agent"
            defaultContainer 'gradle'
            yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: gradle
                    image: gradle:jdk17
                    command:
                    - 'sh'
                    - '-c'
                    - 'git config --global --add safe.directory $(pwd) && exec cat'
                    tty: true
                  - name: docker
                    image: docker
                    command:
                    - 'cat'
                    tty: true
                  - name: kubectl
                    image: lachlanevenson/k8s-kubectl:latest
                    command:
                    - 'cat'
                    tty: true
                  - name: helm
                    image: lachlanevenson/k8s-helm:latest
                    command:
                    - 'cat'
                    tty: true
            """
        }
    }

environment {
    SNYK_TOKEN = credentials('snyk-api-token')
    NEW_RELIC_API_KEY = credentials('newrelic')
    APP_NAME='spring-boot-newrelic'
}

    stages {
        stage('Get Commit Hash') {
            steps {
                script {
                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.COMMIT_HASH = commitHash
                }
            }
        }

        stage('Download and Run Snyk CLI') {
            steps {
                sh '''
                    version=v1.1291.1
                    echo "Downloading Snyk CLI Version: ${version}"

                    architecture=$(uname -m)
                    if [ "$architecture" = "x86_64" ]; then
                        snyk_cli_dl="https://github.com/snyk/snyk/releases/download/${version}/snyk-linux"
                    elif [ "$architecture" = "aarch64" ] || [ "$architecture" = "arm64" ]; then
                        snyk_cli_dl="https://github.com/snyk/snyk/releases/download/${version}/snyk-linux-arm64"
                    else
                        echo "Unsupported architecture: $architecture"
                        exit 1
                    fi

                    echo "Download URL: ${snyk_cli_dl}"

                    curl -Lo ./snyk "${snyk_cli_dl}"
                    chmod +x snyk

                    ./snyk auth ${SNYK_TOKEN}
                    ./snyk test --severity-threshold=critical
                '''
            }
        }

        stage('Build and Test') {
            steps {
                sh '''
                    ./gradlew build
                    ./gradlew test
                '''
            }
            // post {
            //     success {
            //         archiveArtifacts 'build/libs/*.jar'
            //     }
            //     always {
            //         junit 'build/test-results/**/*.xml'
            //     }
            // }
        }

        stage('Notify New Relic') {
            steps {
                sh '''
                    NEW_RELIC_APP_ID=$(curl -s -X GET "https://api.newrelic.com/v2/applications.json" \
                        -H "X-Api-Key:${NEW_RELIC_API_KEY}" \
                        -d "filter[name]=${APP_NAME}" | jq -r '.applications[0].id')

                    curl -X POST "https://api.newrelic.com/v2/applications/${NEW_RELIC_APP_ID}/deployments.json" \
                        -H "X-Api-Key:${NEW_RELIC_API_KEY}" \
                        -H "Content-Type: application/json" \
                        -d "{
                            \"deployment\": {
                                \"revision\": \"${COMMIT_HASH}\",
                                \"changelog\": \"See GitHub for details\",
                                \"description\": \"Deployment triggered by Jenkins\",
                                \"user\": \"Jenkins\"
                            }
                        }"
                '''
            }
        }
    }

}
