pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'godwin1605/alfavox-portfolio'
        DOCKER_TAG = "build-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📦 Checking out source code..."
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "🏗️ Building Docker image..."
                bat "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Test') {
            steps {
                script {
                    echo "🧪 Running container test with dynamic port..."

                    // Stop any old containers based on this image
                    bat 'powershell -Command "docker ps -q --filter \\"ancestor=${DOCKER_IMAGE}\\" | ForEach-Object { docker stop $_; docker rm $_ }"'

                    // Run container and capture only the container ID
                    def output = bat(script: "docker run -d -P ${DOCKER_IMAGE}:${DOCKER_TAG}", returnStdout: true).trim()
                    def lines = output.split("\\r?\\n")
                    def containerId = lines[-1].trim()
                    echo "🚀 Container started with ID: ${containerId}"

                    // Wait for container to start
                    bat 'powershell -Command "Start-Sleep -Seconds 10"'

                    // Get mapped port (host port assigned by Docker)
                    def portOutput = bat(script: "docker port ${containerId} 80/tcp", returnStdout: true).trim()
                    echo "🌐 docker port output: ${portOutput}"

                    // Extract port number (e.g. '0.0.0.0:49158' → '49158')
                    def hostPort = portOutput.split(':')[-1].trim()
                    echo "✅ Mapped Host Port: ${hostPort}"

                    // Test endpoint using curl
                    retry(3) {
                        bat "curl -f http://localhost:${hostPort} || (echo Retry && exit 1)"
                    }

                    echo "🎯 Container responded successfully!"

                    // Cleanup test container
                    bat "docker stop ${containerId}"
                    bat "docker rm ${containerId}"
                }
            }
        }

        stage('Push') {
            when {
                expression { return env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master' }
            }
            steps {
                echo "📤 Pushing Docker image to Docker Hub..."
                bat "docker login -u godwin1605 -p %DOCKERHUB_PASSWORD%"
                bat "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up..."
            bat 'powershell -Command "docker system prune -f"'
        }
        success {
            echo "✅ Build and test completed successfully!"
        }
        failure {
            echo "❌ Build or test failed. Check the logs above."
        }
    }
}
