pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'alfavox-portfolio'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        KUBE_CONFIG = credentials('kubeconfig')
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
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    // Basic test: Check if container starts
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
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push('latest')
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'kubectl apply -f k8s-deployment.yaml'
                    sh 'kubectl set image deployment/alfavox-deployment alfavox-container=alfavox-portfolio:latest'
                    sh 'kubectl rollout status deployment/alfavox-deployment'
                }
            }
        }
    }

    post {
        always {
            sh 'docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
