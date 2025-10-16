pipeline {
    agent any

    environment {
        IMAGE_NAME = "godwin1605/alfavox-portfolio"
        BUILD_TAG = "build-${env.BUILD_NUMBER}"
        CONTAINER_NAME = "test_container"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "🔄 Checking out source code..."
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "🚀 Building Docker image..."
                bat """
                    docker build -t "${IMAGE_NAME}:${BUILD_TAG}" .
                """
            }
        }

        stage('Test') {
            steps {
                script {
                    echo "🧪 Running container test..."

                    // Run container
                    bat """
                        docker run -d -p 8081:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${BUILD_TAG}
                        powershell -Command "Start-Sleep -Seconds 15"
                    """

                    // Properly run PowerShell test command (all in one line)
                    bat """
                        powershell -Command "try { \$r = Invoke-WebRequest -Uri 'http://localhost:8081' -UseBasicParsing; if (\$r.StatusCode -ne 200) { exit 1 } } catch { exit 1 }"
                    """

                    echo "✅ Container responded successfully."

                    // Stop and remove test container cleanly
                    bat "docker stop ${CONTAINER_NAME} || exit 0"
                    bat "docker rm ${CONTAINER_NAME} || exit 0"
                }
            }
        }

        stage('Push Docker Image') {
            when {
                expression { currentBuild.currentResult == 'SUCCESS' }
            }
            steps {
                echo "📤 Pushing Docker image to Docker Hub..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    bat """
                        docker login -u %DOCKER_USER% -p %DOCKER_PASS%
                        docker push ${IMAGE_NAME}:${BUILD_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression { currentBuild.currentResult == 'SUCCESS' }
            }
            steps {
                echo "🚀 Deploying to Kubernetes..."
                bat '''
                    echo "Simulated deploy stage — replace with your kubectl or Helm commands"
                '''
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up test container and image..."
            bat "docker rm -f ${CONTAINER_NAME} || exit 0"
            bat "docker rmi ${IMAGE_NAME}:${BUILD_TAG} || exit 0"
        }

        success {
            echo "✅ Pipeline completed successfully!"
        }

        failure {
            echo "❌ Pipeline failed! Check logs above for details."
        }
    }
}
