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

                    // Stop any containers from previous builds
                    bat 'powershell -Command "docker ps -q --filter \\"ancestor=${DOCKER_IMAGE}\\" | ForEach-Object { docker stop $_; docker rm $_ }"'

                    // Run container with random port assignment
                    def container = bat(script: "docker run -d -P ${DOCKER_IMAGE}:${DOCKER_TAG}", returnStdout: true).trim()
                    echo "🚀 Container started: ${container}"

                    // Wait for container to be ready
                    bat 'powershell -Command "Start-Sleep -Seconds 10"'

                    // Get dynamically mapped port (host port)
                    def containerPort = bat(script: "docker port ${container} 80/tcp", returnStdout: true).trim()
                    echo "🌐 Mapped Port -> ${containerPort}"

                    // Extract just the port number
                    def port = containerPort.split(':')[-1].trim()

                    // Test container endpoint
                    retry(3) {
                        bat "curl -f http://localhost:${port} || (echo Retry && exit 1)"
                    }

                    echo "✅ Container responded successfully on port ${port}!"

                    // Stop and remove container after test
                    bat "docker stop ${container}"
                    bat "docker rm ${container}"
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
