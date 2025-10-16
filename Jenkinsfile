pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'godwin1605/alfavox-portfolio'
        DOCKER_TAG = "build-${env.BUILD_NUMBER}"
        DEPLOYMENT_NAME = 'alfavox-deployment'
        CONTAINER_NAME = 'alfavox-container'
    }

    stages {
        // ... (Checkout and Build stages are fine) ...
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    // CORRECTED: Changed port from 8080 to 8081 to avoid conflict with Jenkins
                    docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").withRun('-p 8081:80') { c ->
                        bat 'timeout /t 10'
                        bat 'curl -f http://localhost:8081 || exit 1'
                    }
                }
            }
        }

        // ... (Push and Deploy stages are fine) ...
        stage('Push Docker Image') {
            steps {
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
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        echo "Deploying to Kubernetes..."
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
                echo "Cleaning up Docker image..."
                bat "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || exit 0"
            }
        }
        success {
            echo 'Pipeline succeeded! 🎉'
        }
        failure {
            echo 'Pipeline failed! 😔'
        }
    }
}