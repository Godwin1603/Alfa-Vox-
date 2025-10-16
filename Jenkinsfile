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
                // Use the built-in Docker pipeline function for better integration
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo "🧪 Running container test..."
                    // This block automatically starts, tests, and cleans up the container
                    docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").withRun('-p 8081:80') { c ->
                        bat 'timeout /t 10' // Wait for Nginx to start
                        bat 'curl -f http://localhost:8081 || exit 1'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "📤 Pushing Docker image to Docker Hub..."
                // SECURE: Uses Jenkins credentials instead of hardcoding passwords
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
                // CORRECT: Deploys to Kubernetes using the secure kubeconfig credential
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
            // Cleanup the build-specific image from the Jenkins agent
            script {
                echo "🧹 Cleaning up Docker image..."
                bat "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || exit 0"
            }
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check logs."
        }
    }
}