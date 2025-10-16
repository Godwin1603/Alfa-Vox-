pipeline {
  agent any

  environment {
    IMAGE_NAME      = "godwin1605/alfavox-portfolio"
    BUILD_TAG       = "build-${env.BUILD_NUMBER}"
    CONTAINER_NAME  = "test_container"
    DEPLOYMENT_NAME = "alfavox-deployment"   // change to your k8s deployment name
    CONTAINER_IN_DEPLOYMENT = "alfavox-container" // change to the container name in the deployment
    // Optional: set these in Jenkins credentials or here as plain text if you prefer (not recommended)
    // EMAIL_RECIPIENTS = "you@example.com"
    // SLACK_WEBHOOK_CRED_ID = "slack-webhook"  // optional - put webhook in Jenkins secret text credential
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
  }

  stages {
    stage('Checkout') {
      steps {
        echo "🔄 Checkout"
        checkout scm
      }
    }

    stage('Build image') {
      steps {
        echo "🚀 Build Docker image ${IMAGE_NAME}:${BUILD_TAG}"
        script {
          if (isUnix()) {
            sh "docker build -t ${IMAGE_NAME}:${BUILD_TAG} ."
          } else {
            bat "docker build -t \"${IMAGE_NAME}:${BUILD_TAG}\" ."
          }
        }
      }
    }

    stage('Test container') {
      steps {
        script {
          echo "🧪 Run container test (port 8081 -> container:80)"
          if (isUnix()) {
            // Linux-friendly test
            sh """
              docker run -d -p 8081:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${BUILD_TAG}
              sleep 8
              if ! curl -fsS http://localhost:8081 > /dev/null; then
                docker logs ${CONTAINER_NAME} || true
                docker rm -f ${CONTAINER_NAME} || true
                exit 1
              fi
              docker stop ${CONTAINER_NAME} || true
              docker rm ${CONTAINER_NAME} || true
            """
          } else {
            // Windows-friendly test using PowerShell
            bat """
              docker run -d -p 8081:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${BUILD_TAG}
              powershell -Command "Start-Sleep -Seconds 12"
            """
            // single-line PowerShell invocation so cmd parsing doesn't break
            bat """powershell -Command "try { \$r = Invoke-WebRequest -Uri 'http://localhost:8081' -UseBasicParsing; if (\$r.StatusCode -ne 200) { Write-Host 'Bad status:' \$r.StatusCode; exit 1 } } catch { Write-Host 'Request failed' ; exit 1 }" """
            bat "docker stop ${CONTAINER_NAME} || exit 0"
            bat "docker rm ${CONTAINER_NAME} || exit 0"
          }
          echo "✅ Container test passed"
        }
      }
    }

    stage('Push to Docker Hub') {
      when {
        expression { currentBuild.currentResult == null || currentBuild.currentResult == 'SUCCESS' }
      }
      steps {
        echo "📤 Pushing ${IMAGE_NAME}:${BUILD_TAG} to Docker Hub"
        script {
          // make sure you add a username/password credential in Jenkins with id 'dockerhub-credentials'
          // Kind: Username with password
          // ID: dockerhub-credentials
          withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            if (isUnix()) {
              sh """
                echo "$DOCKER_PASS" | docker login --username "$DOCKER_USER" --password-stdin
                docker push ${IMAGE_NAME}:${BUILD_TAG}
                docker tag ${IMAGE_NAME}:${BUILD_TAG} ${IMAGE_NAME}:latest
                docker push ${IMAGE_NAME}:latest
                docker logout
              """
            } else {
              // Windows: use %DOCKER_USER% and %DOCKER_PASS%
              bat """
                docker login -u %DOCKER_USER% -p %DOCKER_PASS%
                docker push ${IMAGE_NAME}:${BUILD_TAG}
                docker tag ${IMAGE_NAME}:${BUILD_TAG} ${IMAGE_NAME}:latest
                docker push ${IMAGE_NAME}:latest
                docker logout
              """
            }
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      when {
        expression { currentBuild.currentResult == null || currentBuild.currentResult == 'SUCCESS' }
      }
      steps {
        echo "🚀 Deploying ${IMAGE_NAME}:${BUILD_TAG} to Kubernetes"
        script {
          // Make sure you add a Jenkins "Secret file" credential that contains kubeconfig and ID = 'kubeconfig'
          // It will be available on the agent as the file path in env.KUBECONFIG
          withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
            if (isUnix()) {
              sh """
                # apply manifests if needed (optional)
                # kubectl --kubeconfig=${KUBECONFIG} apply -f k8s-deployment.yaml || true

                # update image and wait for rollout
                kubectl --kubeconfig=${KUBECONFIG} set image deployment/${DEPLOYMENT_NAME} ${CONTAINER_IN_DEPLOYMENT}=${IMAGE_NAME}:${BUILD_TAG} --record
                kubectl --kubeconfig=${KUBECONFIG} rollout status deployment/${DEPLOYMENT_NAME} --timeout=120s
              """
            } else {
              bat """
                kubectl --kubeconfig=%KUBECONFIG% set image deployment/${DEPLOYMENT_NAME} ${CONTAINER_IN_DEPLOYMENT}=${IMAGE_NAME}:${BUILD_TAG} --record
                kubectl --kubeconfig=%KUBECONFIG% rollout status deployment/${DEPLOYMENT_NAME} --timeout=120s
              """
            }
          }
        }
      }
    }
  } // stages

  // rollback behavior and notifications handled in post
  post {
    success {
      echo "✅ Pipeline succeeded — image pushed & deployed"
      // Optional: Slack or email notifications
      // slackSend (channel: '#devops', message: "Deploy succeeded: ${IMAGE_NAME}:${BUILD_TAG}") // needs Slack plugin and config
      // mail to: "${EMAIL_RECIPIENTS}", subject: "Jenkins: Success ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "Build succeeded."
    }

    failure {
      echo "❌ Pipeline failed — attempting rollback and cleanup"
      script {
        // attempt a safe rollback using kubeconfig if present and available
        try {
          withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
            if (isUnix()) {
              sh """
                echo 'Attempting kubectl rollout undo...'
                kubectl --kubeconfig=${KUBECONFIG} rollout undo deployment/${DEPLOYMENT_NAME} || true
                kubectl --kubeconfig=${KUBECONFIG} rollout status deployment/${DEPLOYMENT_NAME} --timeout=120s || true
              """
            } else {
              bat """
                echo Attempting kubectl rollout undo...
                kubectl --kubeconfig=%KUBECONFIG% rollout undo deployment/${DEPLOYMENT_NAME} || exit 0
                kubectl --kubeconfig=%KUBECONFIG% rollout status deployment/${DEPLOYMENT_NAME} --timeout=120s || exit 0
              """
            }
          }
        } catch (err) {
          echo "Rollback attempt failed or kubeconfig not available: ${err}"
        }
      }
      // Optional: send failure notification
      // slackSend (channel: '#devops', message: "Deploy FAILED: ${IMAGE_NAME}:${BUILD_TAG}") // needs Slack plugin and config
      // mail to: "${EMAIL_RECIPIENTS}", subject: "Jenkins: Failure ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "Build failed. See console output."
    }

    always {
      echo "🧹 Global cleanup: remove test container and local image to free disk"
      script {
        if (isUnix()) {
          sh """
            docker rm -f ${CONTAINER_NAME} || true
            docker rmi ${IMAGE_NAME}:${BUILD_TAG} || true
          """
        } else {
          bat """
            docker rm -f ${CONTAINER_NAME} || exit 0
            docker rmi ${IMAGE_NAME}:${BUILD_TAG} || exit 0
          """
        }
      }
    }
  }
}
