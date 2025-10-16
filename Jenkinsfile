pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "godwin1605/alfavox-portfolio"
        DOCKER_TAG   = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "🚀 Building Docker image..."
                bat "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Test') {
            steps {
                script {
                    echo "🧪 Running container test..."

                    // Stop any container on port 8081
                    bat 'for /F "tokens=*" %i in (\'docker ps -q --filter "publish=8081"\') do docker stop %i && docker rm %i || exit 0'

                    // Run test container
                    bat "docker run -d -p 8081:80 --name test_container ${DOCKER_IMAGE}:${DOCKER_TAG}"

                    // Wait for container to start
                    bat 'powershell -Command "Start-Sleep -Seconds 10"'

                    // Check if container responds
                    bat 'curl -f http://localhost:8081 || exit 1'
                }
            }
        }

        stage('Push Docker Image') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo "📦 Pushing Docker image..."
                bat "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }

        stage('Deploy') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo "🚀 Deploying application..."
                // Example deploy command (replace with your real deploy)
                bat "docker stop alfavox || exit 0"
                bat "docker rm alfavox || exit 0"
                bat "docker run -d -p 80:80 --name alfavox ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up test container..."
            bat 'docker rm -f test_container || exit 0'
        }

        success {
            echo "✅ Build, test, and deployment completed successfully!"
        }

        failure {
            echo "❌ Pipeline failed! Check logs for details."
        }
    }
}
