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

                    gitleaks detect --source . --no-banner --redact --exit-code 1
                """
            }
        }

        stage('Compile') {
            steps { sh 'mvn -DskipTests compile' }
        }

        stage('Test') {
            steps { sh 'mvn -DskipTests test' }
        }

        stage('Build') {
            steps { sh 'mvn -DskipTests package' }
        }

        /* ---------------------- SECURITY: GITLEAKS ---------------------- */
        stage('Secrets Scan - Gitleaks') {
            steps {
                sh """
                    echo "Running Gitleaks..."
                    gitleaks detect \
                        --source . \
                        --report-path gitleaks-report.json \
                        --exit-code 0
                """
            }
        }

        /* ---------------------- SECURITY: TRIVY FS ---------------------- */
        stage('Dependency Scan - Trivy Filesystem') {
            steps {
                sh """
                    echo "Running Trivy filesystem scan..."
                    trivy fs --severity HIGH,CRITICAL \
                             --exit-code 0 \
                             --format table .
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
                    trivy image --severity HIGH,CRITICAL \
                                --exit-code 0 \
                                --format table ${DOCKER_IMAGE}:latest
                """
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
