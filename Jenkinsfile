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
        DOCKER_REGISTRY    = 'yourDockerHubUsername'
    }

    stages {

        /* -------------------------- CHECKOUT -------------------------- */

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        /* ---------------------- SECURITY: GITLEAKS ---------------------- */

        stage('Gitleaks Scan') {
            steps {
                sh """
                    echo "Running Gitleaks..."

                    if ! command -v gitleaks > /dev/null; then
                        echo "Installing gitleaks..."
                        curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64 -o gitleaks
                        chmod +x gitleaks
                        sudo mv gitleaks /usr/local/bin/
                    fi

                    gitleaks detect \
                        --source . \
                        --no-banner \
                        --redact \
                        --report-format json \
                        --report-path gitleaks-report.json \
                        --exit-code 1 || true
                """
                archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
            }
        }

        /* ---------------------------- COMPILE ---------------------------- */

        stage('Compile') {
            steps {
                sh 'mvn compile'
            }
        }

        /* ----------------------------- TEST ------------------------------ */

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        /* ----------------------------- BUILD ----------------------------- */

        stage('Build JAR') {
            steps {
                sh 'mvn package'
            }
        }

        /* ---------------------- SECURITY: TRIVY FS ---------------------- */

        stage('Dependency Scan - Trivy FS') {
            steps {
                sh """
                    echo "Running Trivy filesystem scan..."

                    trivy fs \
                        --severity HIGH,CRITICAL \
                        --format json \
                        --output trivy-fs-report.json \
                        --exit-code 0 .
                """
                archiveArtifacts artifacts: 'trivy-fs-report.json', allowEmptyArchive: true
            }
        }

        /* --------------------------- DOCKER BUILD ---------------------------- */

        stage('Docker Image Build') {
            steps {
                sh """
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE}:latest .
                """
            }
        }

        /* ---------------------- SECURITY: TRIVY IMAGE ---------------------- */

        stage('Docker Image Scan - Trivy') {
            steps {
                sh """
                    echo "Running Trivy image scan..."

                    trivy image \
                        --severity HIGH,CRITICAL \
                        --timeout 15m \
                        --format json \
                        --output trivy-image-report.json \
                        --exit-code 0 \
                        ${DOCKER_IMAGE}:latest
                """
                archiveArtifacts artifacts: 'trivy-image-report.json', allowEmptyArchive: true
            }
        }

        /* --------------------------- SONARQUBE ---------------------------- */

        stage('SonarQube Analysis') {
            tools {
                jdk 'JAVA_HOME'   // Java 21 for Sonar only
            }
            steps {
                withCredentials([string(credentialsId: 'Sonarqube', variable: 'SONAR_TOKEN')]) {
                    sh """
                        mvn sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }
    }
} 