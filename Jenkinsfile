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

        /* --------------------------- DOCKER BUILD ---------------------------- */
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

        /* --------------------------------------------------------
           TRIVY SCANNING STAGE
        -------------------------------------------------------- */
        stage('Trivy Scan') {
            steps {
                sh """
                    echo "Running Trivy scan..."

                    if ! command -v trivy > /dev/null; then
                        echo "Installing Trivy..."
                        sudo apt-get update -y
                        sudo apt-get install -y wget apt-transport-https gnupg lsb-release
                        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                        echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/trivy.list
                        sudo apt-get update -y
                        sudo apt-get install -y trivy
                    fi

                    echo "Scanning local filesystem..."
                    trivy fs . --exit-code 0 --severity HIGH,CRITICAL

                    echo "Scanning Docker image..."
                    trivy image ${DOCKER_IMAGE}:latest --exit-code 0 --severity HIGH,CRITICAL
                """
            }
        }

        /* --------------------------- SONARQUBE ---------------------------- */
        stage('SonarQube Analysis') {
            tools {
                jdk 'JAVA_HOME'  // Java 21 only for Sonar
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
