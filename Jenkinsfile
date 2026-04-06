pipeline {
    agent any
    
    environment {
        APP_NAME = "cicd-demo-app"
        DOCKER_IMAGE = "${APP_NAME}:${BUILD_NUMBER}"
        K8S_NAMESPACE = "default"
        KIND_CLUSTER = "cicd-cluster"
    }
    
    tools {
        maven 'Maven-3.6'
        jdk 'JDK-17'
    }
    
    stages {
        stage('🔍 Validate Commit Message') {
            steps {
                script {
                    echo "=== Validating Conventional Commit Message ==="
                    def commitMessage = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    echo "Commit Message: ${commitMessage}"
                    def pattern = /^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?!?: .{1,100}/
                    if (!(commitMessage =~ pattern)) {
                        error "❌ Invalid commit message format!\nExpected: <type>(<scope>): <subject>\nYour commit: ${commitMessage}"
                    }
                    echo "✅ Commit message is valid"
                }
            }
        }
        
        stage('📦 Build Application') {
            steps {
                echo "=== Building Application with Maven ==="
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('🧪 Run Tests') {
            steps {
                echo "=== Running Unit Tests ==="
                sh 'mvn test'
            }
        }
        
        stage('🐳 Build Docker Image') {
            steps {
                script {
                    echo "=== Building Docker Image ==="
                    sh """
                        docker build -t ${DOCKER_IMAGE} .
                        docker tag ${DOCKER_IMAGE} ${APP_NAME}:latest
                    """
                    echo "✅ Docker image built: ${DOCKER_IMAGE}"
                }
            }
        }
        
        stage('📤 Load Image to KIND') {
            steps {
                script {
                    echo "=== Loading Docker Image into KIND Cluster ==="
                    sh "kind load docker-image ${DOCKER_IMAGE} --name ${KIND_CLUSTER}"
                    echo "✅ Image loaded into KIND cluster"
                }
            }
        }
        
        stage('🚀 Deploy to Kubernetes') {
            steps {
                script {
                    echo "=== Deploying to Kubernetes ==="

                    // Apply manifests first time, then update image
                    sh """
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    """

                    // ✅ Use kubectl set image instead of sed (permanent fix!)
                    sh """
                        kubectl set image deployment/${APP_NAME} \
                        ${APP_NAME}=${DOCKER_IMAGE}
                    """

                    echo "✅ Deployment updated with image: ${DOCKER_IMAGE}"
                }
            }
        }
        
        stage('✅ Verify Deployment') {
            steps {
                script {
                    echo "=== Verifying Deployment ==="
                    sh "kubectl rollout status deployment/${APP_NAME} --timeout=300s"
                    sh """
                        echo "=== Pods ==="
                        kubectl get pods -l app=${APP_NAME}
                        
                        echo "=== Services ==="
                        kubectl get svc ${APP_NAME}-service
                        
                        echo "=== Deployment ==="
                        kubectl get deployment ${APP_NAME}
                    """
                    echo "✅ Deployment verified successfully"
                }
            }
        }
        
        stage('🌐 Get Access URL') {
            steps {
                script {
                    def nodeIP = sh(
                        script: "kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'",
                        returnStdout: true
                    ).trim()
                    echo """
                    ╔══════════════════════════════════════════╗
                    ║      🎉 DEPLOYMENT SUCCESSFUL 🎉          ║
                    ╠══════════════════════════════════════════╣
                    ║  curl http://${nodeIP}:30080              ║
                    ║  curl http://${nodeIP}:30080/version      ║
                    ║  curl http://${nodeIP}:30080/health       ║
                    ╚══════════════════════════════════════════╝
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline executed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs for details.'
        }
        always {
            echo '🧹 Cleaning up workspace...'
            cleanWs()
        }
    }
}
