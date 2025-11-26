pipeline {
    agent any

    tools {
        jdk 'jdk11'        // Must match the JDK name in Jenkins
        maven 'M2_HOME'    // Must match Maven name in Jenkins
    }

    environment {
        SONAR_HOST_URL     = 'http://localhost:9000'
        SONAR_PROJECT_KEY  = 'boardgame'
        SONAR_PROJECT_NAME = 'boardgame'
    }

    stages {

        stage('Compile') {
            steps {
                sh 'mvn compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn package'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'Sonarqube', variable: 'SONAR_TOKEN')]) {
                    sh """
                        mvn clean verify sonar:sonar \
                          -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

    }

    post {
        always {
            echo "Pipeline finished."
        }
        success {
            echo "Pipeline completed successfully."
        }
        failure {
            echo "Pipeline failed."
        }
    }
}
