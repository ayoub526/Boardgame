pipeline {
    agent any

    tools {
        jdk 'jdk11'
        maven 'M2_HOME'
    }

    environment {
        SONAR_HOST_URL     = 'http://localhost:9000'
        SONAR_PROJECT_KEY  = 'boardgame'
        SONAR_PROJECT_NAME = 'boardgame'
        DOCKER_IMAGE       = 'boardgame-app'
        DOCKER_REGISTRY    = 'yourDockerHubUsername'   // <--- change this or remove
    }

    stages {

        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Compile') {
            steps { sh 'mvn compile' }
        }

        stage('Test') {
            steps { sh 'mvn test' }
        }

        stage('Build') {
            steps { sh 'mvn package' }
        }

        /* --------------------------- DOCKER BUILD STAGE ---------------------------- */
        stage('Docker Image Build') {
            steps {
                script {
                    sh """
                        echo "Building Docker image..."
                        docker build -t ${DOCKER_IMAGE}:latest .
                    """
                }
            }
        }

        /* --------------------------- SONARQUBE STAGE ---------------------------- */
        stage('SonarQube Analysis') {
            tools {
                jdk 'JAVA_HOME'    // SWITCH to Java 21 ONLY HERE
            }
            steps {
                withCredentials([string(credentialsId: 'Sonarqube', variable: 'SONAR_TOKEN')]) {
                    sh """
                        mvn -DskipTests=true sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }
    }
}
