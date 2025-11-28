pipeline {
    agent any

    tools {
        jdk 'jdk11'          // Your project uses Java 11
        maven 'M2_HOME'      // Your configured Maven tool
    }

    environment {
        SONAR_HOST_URL     = 'http://localhost:9000'
        SONAR_PROJECT_KEY  = 'boardgame'
        SONAR_PROJECT_NAME = 'boardgame'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

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

        stage('Build JAR') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }

        stage('SonarQube Analysis (JDK 17)') {
            steps {
                // Switch only this stage to JDK 17
                tool name: 'jdk17', type: 'jdk'
                withEnv(["JAVA_HOME=${tool 'jdk17'}", "PATH+JDK=${tool 'jdk17'}/bin"]) {
                    withCredentials([string(credentialsId: 'Sonarqube', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            mvn clean verify sonar:sonar \
                              -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                              -Dsonar.host.url=${SONAR_HOST_URL} \
                              -Dsonar.login=$SONAR_TOKEN \
                              -DskipTests=true
                        '''
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t boardgame-app:latest .'
            }
        }

        stage('Docker Run (Optional)') {
            steps {
                sh 'docker run -d -p 8080:8080 --name boardgame-test boardgame-app:latest || true'
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
        success {
            echo "SUCCESS: Build + Tests + Sonar + Docker image completed."
        }
        failure {
            echo "Pipeline FAILED – check logs."
        }
    }
}
