pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "godwin1605/alfavox-portfolio"
        DOCKER_TAG   = "build-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo "🔄 Checking out source code..."
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "🚀 Building Docker image..."
                bat "docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% ."
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
                    bat 'curl -f http://localhost:8081'

                    // Stop test container after test
                    bat "docker stop test_container & docker rm test_container || exit 0"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "📤 Pushing Docker image to Docker Hub..."
                // Use Jenkins credentials instead of plain username/password if possible
                bat "docker login -u YOUR_DOCKERHUB_USERNAME -p YOUR_DOCKERHUB_PASSWORD"
                bat "docker push %DOCKER_IMAGE%:%DOCKER_TAG%"
            }
        }

        stage('Deploy') {
            steps {
                echo "🚀 Deploying application..."
                // Stop any old container
                bat """
                for /F "tokens=*" %%i in ('docker ps -q --filter "name=alfavox-portfolio"') do (
                    docker stop %%i
                    docker rm %%i
                )
                """
                
                // Start new container
                bat "docker run -d -p 80:80 --name alfavox-portfolio %DOCKER_IMAGE%:%DOCKER_TAG%"
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up test container..."
            bat "docker rm -f test_container || exit 0"
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check logs."
        }
    }
}
