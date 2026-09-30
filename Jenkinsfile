pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        BACKEND_IMAGE  = "ghaith5/node-stock-app"
        FRONTEND_IMAGE = "ghaith5/node-stock-frontend"
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('clean up') {
            steps {
                sh 'docker system prune -f || true'
            }
        }

        stage('clonage du code') {
            steps {
                sh 'echo "Code deja recupere par Checkout SCM — etape conservee pour correspondre au pipeline de reference."'
                sh 'git log -1 --oneline'
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
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
            }
        }

        stage('Generation de l\'image backend') {
            steps {
                sh 'docker build -t $BACKEND_IMAGE:$IMAGE_TAG -t $BACKEND_IMAGE:latest ./app'
                sh 'docker push $BACKEND_IMAGE:$IMAGE_TAG'
                sh 'docker push $BACKEND_IMAGE:latest'
            }
        }

        stage('Generation de l\'image frontend') {
            steps {
                sh 'docker build -f nginx/Dockerfile -t $FRONTEND_IMAGE:$IMAGE_TAG -t $FRONTEND_IMAGE:latest .'
                sh 'docker push $FRONTEND_IMAGE:$IMAGE_TAG'
                sh 'docker push $FRONTEND_IMAGE:latest'
            }
        }

        stage('Deploy kubernetes') {
            when {
                expression { env.GIT_BRANCH == 'origin/main' || env.GIT_BRANCH == 'main' }
            }
            steps {
                // NOTE: this cluster is also managed by ArgoCD (GitOps, auto-sync
                // from the k8s/ folder in Git). Applying manifests directly here
                // works, but ArgoCD's selfHeal will eventually revert any change
                // that isn't also reflected in Git — so this stage and ArgoCD
                // should agree on the same source of truth.
                sh 'kubectl set image deployment/app app=$BACKEND_IMAGE:$IMAGE_TAG -n stock-multi-depot'
                sh 'kubectl set image deployment/nginx nginx=$FRONTEND_IMAGE:$IMAGE_TAG -n stock-multi-depot'
                sh 'kubectl rollout status deployment/app -n stock-multi-depot'
                sh 'kubectl rollout status deployment/nginx -n stock-multi-depot'
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
