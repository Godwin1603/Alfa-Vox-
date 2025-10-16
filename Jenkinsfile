pipeline {
    agent any

    environment {
        // CORRECTED: Your Docker Hub username is prefixed to the image name.
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
                    ddocker.build("${DOCKER_IMAGE}:${DOCKER_TAG}") // Correct line
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    // Basic test: Check if container starts and responds.
                    docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").withRun('-p 8080:80') { c ->
                        sh 'sleep 10'
                        sh 'curl -f http://localhost:8080 || exit 1'
                    }
                }
            }
        }

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
                // CORRECTED: The kubectl commands are wrapped to securely use your kubeconfig credential.
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        echo "Deploying to Kubernetes..."
                        sh 'kubectl apply -f k8s-deployment.yaml'
                        sh "kubectl set image deployment/${DEPLOYMENT_NAME} ${CONTAINER_NAME}=${DOCKER_IMAGE}:latest"
                        sh "kubectl rollout status deployment/${DEPLOYMENT_NAME}"
                    }
                }
            }
        }
    }

    post {
        always {
            // CORRECTED: The cleanup command is wrapped in a script block to avoid context errors.
            script {
                echo "Cleaning up Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                sh "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true"
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