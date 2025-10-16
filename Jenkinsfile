pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'godwin1605/alfavox-portfolio'
        DOCKER_TAG = "build-${env.BUILD_NUMBER}"
        DEPLOYMENT_NAME = 'alfavox-deployment'
        CONTAINER_NAME = 'alfavox-container'
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
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo "🧪 Running container test..."

                    // Stop and remove any container on port 8081 safely
                    bat """
                    for /F "tokens=*" %%i in ('docker ps -q --filter "publish=8081"') do (
                        docker stop %%i
                        docker rm %%i
                    )
                    """

                    // Run a new test container
                    bat "docker run -d -p 8081:80 --name test_container %DOCKER_IMAGE%:%DOCKER_TAG%"

                    // Wait a few seconds for container to start
                    bat 'powershell -Command "Start-Sleep -Seconds 5"'

                    // Test container response
                    bat 'curl -f http://localhost:8081 || exit 1'

                    // Stop test container after test
                    bat "docker stop test_container & docker rm test_container || exit 0"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "📤 Pushing Docker image to Docker Hub..."
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                        def img = docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        img.push()
                        img.push('latest')
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "🚀 Deploying application to Kubernetes..."
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    bat 'kubectl apply -f k8s-deployment.yaml'
                    bat "kubectl set image deployment/${DEPLOYMENT_NAME} ${CONTAINER_NAME}=${DOCKER_IMAGE}:latest"
                    bat "kubectl rollout status deployment/${DEPLOYMENT_NAME}"
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up test container and image..."
            bat 'docker rm -f test_container || exit 0'
            bat "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || exit 0"
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check logs above for details."
        }
    }
}
