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
                    
                    // Get the last commit message
                    def commitMessage = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    
                    echo "Commit Message: ${commitMessage}"
                    
                    // Conventional commit pattern
                    def pattern = /^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?!?: .{1,100}/
                    
                    if (!(commitMessage =~ pattern)) {
                        error """
                        ❌ Invalid commit message format!
                        
                        Expected format: <type>(<scope>): <subject>
                        
                        Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
                        
                        Examples:
                        - feat: add user authentication
                        - fix(api): resolve null pointer exception
                        - docs: update README with setup instructions
                        
                        Your commit: ${commitMessage}
                        """
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
                    
                    // Update deployment with new image tag
                    sh """
                        sed -i 's|image: cicd-demo-app:BUILD_NUMBER|image: ${DOCKER_IMAGE}|g' k8s/deployment.yaml
                        cat k8s/deployment.yaml
                    """
                    
                    // Apply Kubernetes manifests
                    sh """
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    """
                    
                    echo "✅ Deployment applied"
                }
            }
        }
        
        stage('✅ Verify Deployment') {
            steps {
                script {
                    echo "=== Verifying Deployment ==="
                    
                    // Wait for rollout to complete
                    sh "kubectl rollout status deployment/${APP_NAME} --timeout=300s"
                    
                    // Get deployment info
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
                    echo "=== Application Access Information ==="
                    
                    def nodeIP = sh(
                        script: "kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'",
                        returnStdout: true
                    ).trim()
                    
                    echo """
                    ╔════════════════════════════════════════════════════════════╗
                    ║          🎉 DEPLOYMENT SUCCESSFUL 🎉                       ║
                    ╠════════════════════════════════════════════════════════════╣
                    ║                                                            ║
                    ║  Application URL (from EC2):                               ║
                    ║  http://${nodeIP}:30080                                    ║
                    ║                                                            ║
                    ║  Application URL (from browser):                           ║
                    ║  http://YOUR_EC2_PUBLIC_IP:30080                           ║
                    ║                                                            ║
                    ║  Test command:                                             ║
                    ║  curl http://${nodeIP}:30080                               ║
                    ║                                                            ║
                    ╚════════════════════════════════════════════════════════════╝
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
