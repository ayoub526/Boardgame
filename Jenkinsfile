pipeline {
    agent any

    tools {
        jdk 'jdk11'
        maven 'M2_HOME'
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
    }
}
