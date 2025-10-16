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
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🚀 Building Docker image..."
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo "🧪 Running container test..."

                    // Stop any old containers using port 8081
                    bat 'powershell -Command "docker ps -q --filter \\"publish=8081\\" | ForEach-Object { docker stop $_; docker rm $_ }"'

                    // Run the container and test
                    docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").withRun('-p 8081:80') { c ->
                        // Wait for container to start
                        bat 'powershell -Command "Start-Sleep -Seconds 10"'

                        // Show running containers
                        bat "docker ps -a"

                        // Retry curl test in case container is still starting
                        retry(3) {
                            bat 'curl -f http://localhost:8081 || (echo Retry && exit 1)'
                        }

                        echo "✅ Container responded successfully!"
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "📦 Pushing image to Docker Hub..."
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
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        echo "🚢 Deploying to Kubernetes..."
                        bat 'kubectl apply -f k8s-deployment.yaml'
                        bat "kubectl set image deployment/${DEPLOYMENT_NAME} ${CONTAINER_NAME}=${DOCKER_IMAGE}:latest"
                        bat "kubectl rollout status deployment/${DEPLOYMENT_NAME}"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "🧹 Cleaning up Docker image..."
                bat "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || exit 0"
            }
        }
        success {
            echo '🎉 Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
