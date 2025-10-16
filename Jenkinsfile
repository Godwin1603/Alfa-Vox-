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

            // Stop and remove any previous test container safely
            bat 'docker rm -f test_container || echo "No existing test container"'

            // Run new test container
            bat "docker run -d -p 8081:80 --name test_container %DOCKER_IMAGE%:%DOCKER_TAG%"

            // Give container a few seconds to start
            bat 'powershell -Command "Start-Sleep -Seconds 5"'

            // Test container response (requires curl)
            bat 'curl -f http://localhost:8081 || exit 1'

            // Stop and remove test container
            bat 'docker stop test_container & docker rm test_container || echo "Cleanup done"'
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
