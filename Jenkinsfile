pipeline {
    agent any

    environment {
        SNYK_TOKEN = credentials('snyk-api-token')
        NEW_RELIC_API_KEY = credentials('newrelic-api-key')
        KUBECONFIG = credentials('kubeconfig')
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/marublaize/spring-boot-newrelic.git'
            }
        }

        stage('Snyk Security Scan') {
            steps {
                script {
                    sh 'snyk auth $SNYK_TOKEN'
                    sh 'snyk test'
                }
            }
        }

        stage('Build') {
            steps {
                sh './gradlew clean build'
            }
        }

        stage('Test') {
            steps {
                sh './gradlew test'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'kubectl --kubeconfig=$KUBECONFIG apply -f kubernetes/deployment.yaml'
                }
            }
        }

stage('Get New Relic Application ID') {
    steps {
        script {
            def newRelicApiKey = credentials('newrelic-api-key')
            def applicationName = 'Your Application Name' // Replace with your application name
            def apiUrl = "https://api.newrelic.com/v2/applications.json?filter[name]=${applicationName}"

            def response = sh (
                script: "curl -s -X GET -H 'X-Api-Key:${newRelicApiKey}' '${apiUrl}'",
                returnStdout: true
            ).trim()

            def applicationId = sh (
                script: "echo '${response}' | jq -r '.applications[0].id'",
                returnStdout: true
            ).trim()

            env.NEW_RELIC_APP_ID = applicationId
        }
    }
}

        stage('Notify New Relic') {
            steps {
                script {
                    sh '''
                        curl -X POST "https://api.newrelic.com/v2/applications/${NEW_RELIC_APP_ID}/deployments.json" \
                        -H "X-Api-Key:${NEW_RELIC_API_KEY}" \
                        -H "Content-Type: application/json" \
                        -d '{
                            "deployment": {
                                "revision": "${GIT_COMMIT}",
                                "changelog": "See GitHub for details",
                                "description": "Deployment triggered by Jenkins",
                                "user": "Jenkins"
                            }
                        }'
                    '''
                }
            }
        }
    }

    post {
        always {
            junit 'build/test-results/test/*.xml'
            archiveArtifacts artifacts: 'build/libs/*.jar', allowEmptyArchive: true
        }
    }
}
