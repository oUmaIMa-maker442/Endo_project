pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "oumaimalah/endo-mhealth"
        DOCKER_TAG = "${BUILD_NUMBER}"
        SONAR_HOST_URL = "http://localhost:9005"
        ANDROID_HOME = "C:\\Users\\ADMIN\\AppData\\Local\\Android\\Sdk"
        KUBECONFIG = "C:\\ProgramData\\Jenkins\\.kube\\config"
    }

    stages {

        stage('1 - Checkout') {
            steps {
                git branch: 'feature/ci-cd-pipeline',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/oUmaIMa-maker442/Endo_project.git'
                echo "Commit : ${GIT_COMMIT} - Build avance #${BUILD_NUMBER}"
            }
        }

        stage('2 - Build Gradle') {
            steps {
                bat '.\\gradlew.bat clean assembleDebug --no-daemon'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'app/build/outputs/apk/**/*.apk',
                        fingerprint: true
                }
            }
        }

        stage('3 - Tests Unitaires') {
            steps {
                bat '.\\gradlew.bat test --no-daemon'
                echo "Tests unitaires termines"
            }
            post {
                always {
                    junit testResults: 'app/build/test-results/**/*.xml',
                        allowEmptyResults: true
                }
                failure {
                    echo "ECHEC tests - deploiement bloque"
                }
            }
        }

        stage('4 - Analyse SonarQube') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('SonarQube-Local') {
                        bat """gradlew.bat sonar ^
                        -Dsonar.projectKey=Endo-mHealth ^
                        -Dsonar.projectName=Endo-mHealth ^
                        -Dsonar.host.url=http://localhost:9005 ^
                        -Dsonar.token=%SONAR_TOKEN% ^
                        --no-daemon"""
                    }
                }
                sleep(time: 60, unit: 'SECONDS')
                echo "Analyse SonarQube terminee"
            }
        }

        stage('5 - Docker Build et Push') {
            steps {
                bat "docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% ."
                bat "docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest"

                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS')]) {

                    bat 'echo %DOCKER_PASS%| docker login -u %DOCKER_USER% --password-stdin'
                    bat "docker push %DOCKER_IMAGE%:%DOCKER_TAG%"
                    bat "docker push %DOCKER_IMAGE%:latest"
                }
            }
        }

        stage('6 - Deploy Kubernetes') {
            steps {
                bat 'minikube status || minikube start --driver=docker'
                bat 'kubectl config use-context minikube'
                bat 'kubectl create namespace mhealth || echo namespace existe deja'
                bat 'kubectl delete deployment endo-deployment -n mhealth || echo not found'
                bat 'kubectl delete service endo-service -n mhealth || echo not found'
                bat 'kubectl apply -f k8s\\deployment.yaml -n mhealth'
                bat 'kubectl apply -f k8s\\service.yaml -n mhealth'
                bat 'timeout /t 15'
                bat 'kubectl rollout status deployment/endo-deployment -n mhealth --timeout=300s'
            }
            post {
                failure {
                    bat 'kubectl rollout undo deployment/endo-deployment -n mhealth || echo rollback impossible'
                    echo "ROLLBACK automatique declenche"
                }
            }
        }
    }

    post {
        success { echo "PIPELINE AVANCE REUSSI - Build ${BUILD_NUMBER}" }
        failure { echo "PIPELINE AVANCE ECHOUE - Build ${BUILD_NUMBER}" }
        always { echo "Duree : ${currentBuild.durationString}" }
    }
}