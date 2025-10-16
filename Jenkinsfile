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

                    // Start and test the container
                    docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").withRun('-p 8081:80 --name test_container') { c ->

                        // Wait for container startup
                        bat 'powershell Start-Sleep -Seconds 15'

                        // Perform a simple HTTP GET request to verify Nginx is running
                        def testResult = bat(
                            script: 'powershell -Command "try { $r = Invoke-WebRequest -Uri http://localhost:8081 -UseBasicParsing; if ($r.StatusCode -ne 200) { exit 1 } } catch { exit 1 }"',
                            returnStatus: true
                        )

                        if (testResult != 0) {
                            error("❌ Container test failed! HTTP request did not return status 200.")
                        } else {
                            echo "✅ Container responded successfully."
                        }
                    }
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
