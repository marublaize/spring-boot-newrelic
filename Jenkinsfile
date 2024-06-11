pipeline {
    agent {
        kubernetes {
            label "jenkins-agent-${JOB_NAME}"
            defaultContainer 'gradle'
            yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: gradle
                    image: gradle:jdk17
                    command:
                    - 'cat'
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

    stages {
        stage('Download and Run Snyk CLI') {
            steps {
                sh '''
                    version=v1.1291.1
                    echo "Downloading Snyk CLI Version: ${version}"

                    architecture=$(uname -m)
                    if [ "$architecture" == "x86_64" ]; then
                        snyk_cli_dl="https://github.com/snyk/snyk/releases/download/${version}/snyk-linux"
                    elif [ "$architecture" == "aarch64" ] || [ "$architecture" == "arm64" ]; then
                        snyk_cli_dl="https://github.com/snyk/snyk/releases/download/${version}/snyk-linux-arm64"
                    else
                        echo "Unsupported architecture: $architecture"
                        exit 1
                    fi

                    echo "Download URL: ${snyk_cli_dl}"

                    curl -Lo ./snyk "${snyk_cli_dl}"
                    chmod +x snyk

                    ./snyk -v
                    ./snyk test
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
            post {
                success {
                    archiveArtifacts 'build/libs/*.jar'
                }
                always {
                    junit 'build/test-results/**/*.xml'
                }
            }
        }
    }
}
