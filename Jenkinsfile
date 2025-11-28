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

        stage('Checkout') {
            steps { checkout scm }
        }

        /* --------------------------------------------------------
           GITLEAKS STAGE
        -------------------------------------------------------- */
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

                    # JSON + HTML reports
                    gitleaks detect \
                        --source . \
                        --no-banner \
                        --redact \
                        --report-format json \
                        --report-path gitleaks-report.json \
                        --exit-code 1

                    gitleaks detect \
                        --source . \
                        --no-banner \
                        --redact \
                        --report-format html \
                        --report-path gitleaks-report.html \
                        --exit-code 0
                """
            }
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

        /* ---------------------- SECURITY: GITLEAKS ---------------------- */
        stage('Secrets Scan - Gitleaks') {
            steps {
                sh """
                    echo "Running Gitleaks..."
                    gitleaks detect \
                        --source . \
                        --report-path gitleaks-second.json \
                        --report-format json \
                        --exit-code 0

                    gitleaks detect \
                        --source . \
                        --report-path gitleaks-second.html \
                        --report-format html \
                        --exit-code 0
                """
            }
        }

        /* ---------------------- SECURITY: TRIVY FS ---------------------- */
        stage('Dependency Scan - Trivy Filesystem') {
            steps {
                sh """
                    echo "Running Trivy filesystem scan..."

                    trivy fs \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format table \
                        . > trivy-fs-table.txt

                    # HTML report
                    trivy fs \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format template \
                        --template "@contrib/html.tpl" \
                        --output trivy-fs-report.html \
                        .
                """
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
                        --exit-code 0 \
                        --format table \
                        ${DOCKER_IMAGE}:latest > trivy-image-table.txt

                    # HTML report
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --timeout 15m \
                        --exit-code 0 \
                        --format template \
                        --template "@contrib/html.tpl" \
                        --output trivy-image-report.html \
                        ${DOCKER_IMAGE}:latest
                """
            }
        }

        /* --------------------------- SONARQUBE ---------------------------- */
        stage('SonarQube Analysis') {
            tools {
                jdk 'JAVA_HOME'
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

    post {
        always {
            archiveArtifacts artifacts: '*.html, *.json, *.txt', fingerprint: true
        }
    }
}
