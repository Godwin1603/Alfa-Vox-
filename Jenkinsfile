pipeline {
    agent any
    
    environment {
        GCP_PROJECT = 'your-project-id'
        GKE_CLUSTER = 'aifa-cluster'
        GKE_ZONE = 'us-central1'
        IMAGE = "gcr.io/${GCP_PROJECT}/aifa-backend"
    }
    
    stages {
        stage('Test') {
            steps {
                sh 'npm install'
                sh 'npm test'
            }
        }
        
        stage('Build') {
            steps {
                script {
                    docker.build("${IMAGE}:${env.BUILD_ID}")
                }
            }
        }
        
        stage('Push') {
            steps {
                script {
                    docker.withRegistry('https://gcr.io', 'gcp-auth') {
                        docker.image("${IMAGE}:${env.BUILD_ID}").push()
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        
        stage('Deploy to GKE') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-key', variable: 'GCP_KEY')]) {
                        sh "gcloud auth activate-service-account --key-file=${GCP_KEY}"
                        sh "gcloud container clusters get-credentials ${GKE_CLUSTER} --zone ${GKE_ZONE} --project ${GCP_PROJECT}"
                        sh "kubectl set image deployment/aifa-backend aifa-backend=${IMAGE}:${env.BUILD_ID}"
                        sh "kubectl rollout status deployment/aifa-backend"
                    }
                }
            }
        }
    }
}