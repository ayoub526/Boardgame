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

        stage('SonarQube Analysis') {
            tools {
                jdk 'JAVA_HOME'   //  SWITCH to java 17 ONLY HERE
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
