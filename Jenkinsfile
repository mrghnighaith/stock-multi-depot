pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Lint PHP') {
            steps {
                sh 'chmod +x scripts/lint.sh'
                sh './scripts/lint.sh'
            }
        }

        stage('Build Images') {
            steps {
                sh 'docker compose -f docker-compose.yml build'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh 'docker compose down'
                sh 'docker compose up -d --build'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed — check the stage logs above.'
        }
    }
}
