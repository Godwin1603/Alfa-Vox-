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
                    echo "🧪 Running container test..."

                    // Stop any container using same port
                    bat '''
                        for /f "tokens=*" %%i in ('docker ps -q --filter "publish=8081"') do docker stop %%i && docker rm %%i
                    '''

                    // Run test container on 8081
                    bat "docker run -d -p 8081:80 --name test_container ${DOCKER_IMAGE}:${DOCKER_TAG}"

                    // Wait for container startup
                    bat 'powershell -Command "Start-Sleep -Seconds 8"'

                    // Check if running
                    bat "docker ps | findstr test_container"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "📤 Pushing Docker image to Docker Hub..."
                    // Login first (store Docker credentials in Jenkins Credentials Manager as 'docker-hub-creds')
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        bat "docker login -u %DOCKER_USER% -p %DOCKER_PASS%"
                    }
                    bat "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "🚀 Deploying latest build locally on port 8081..."

                    // Stop any previous deployment
                    bat '''
                        for /f "tokens=*" %%i in ('docker ps -q --filter "name=alfavox"') do docker stop %%i && docker rm %%i
                    '''

                    // Run new container
                    bat "docker run -d -p 8081:80 --name alfavox ${DOCKER_IMAGE}:${DOCKER_TAG}"

                    echo "✅ Deployment successful! App is running on http://localhost:8081"
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Build, Test, and Deploy completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check logs for details."
        }
        always {
            echo "🧹 Cleaning up test container..."
            bat 'docker rm -f test_container || exit 0'
        }
    }
}
