pipeline {
    agent any

    environment {
        DOCKERHUB_CRED = 'dockerhub-credentials'
        BACKEND_IMAGE  = "ghaith5/stock-backend:${BUILD_NUMBER}"
        FRONTEND_IMAGE = "ghaith5/stock-nginx:${BUILD_NUMBER}"
        K8S_NAMESPACE  = 'stock-multi-depot'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Clean up') {
            steps {
                sh 'docker system prune -f || true'
            }
        }

        stage('Clonage du code') {
            steps {
                sh 'ls -la'
            }
        }

        stage('Lint PHP') {
            steps {
                sh 'chmod +x scripts/lint.sh'
                sh './scripts/lint.sh'
            }
        }

        stage('Login to docker') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CRED}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        stage('backend image') {
            steps {
                sh '''
                    docker build -t $BACKEND_IMAGE -t ghaith5/stock-backend:latest ./app
                    docker push $BACKEND_IMAGE
                    docker push ghaith5/stock-backend:latest
                '''
            }
        }

        stage('frontend image') {
            steps {
                sh '''
                    docker build -t $FRONTEND_IMAGE -t ghaith5/stock-nginx:latest -f nginx/Dockerfile .
                    docker push $FRONTEND_IMAGE
                    docker push ghaith5/stock-nginx:latest
                '''
            }
        }

        stage('Deploy kubernetes') {
            steps {
                sh """
                    kubectl -n $K8S_NAMESPACE set image deployment/app   app=\$BACKEND_IMAGE
                    kubectl -n $K8S_NAMESPACE set image deployment/nginx nginx=\$FRONTEND_IMAGE
                    kubectl -n $K8S_NAMESPACE rollout status deployment/app   --timeout=120s
                    kubectl -n $K8S_NAMESPACE rollout status deployment/nginx --timeout=120s
                """
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed — check the stage logs above.'
        }
    }
}
